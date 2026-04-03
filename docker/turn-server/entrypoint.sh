#!/bin/sh
set -eu

conf_template="/etc/turn-server/config.toml.tmpl"
conf_rendered="/tmp/turn-server.toml"
caddy_cert_root="/caddy-certs/caddy/certificates"

: "${TURN_REALM:?TURN_REALM is required}"
: "${TURN_SHARED_SECRET:?TURN_SHARED_SECRET is required}"
: "${EXTERNAL_IP:?EXTERNAL_IP is required}"

discover_tls_files() {
  cert_file=""
  key_file=""

  if [ -d "${caddy_cert_root}" ]; then
    cert_file=$(find "${caddy_cert_root}" -path "*/${TURN_REALM}/${TURN_REALM}.crt" -print -quit)
    key_file=$(find "${caddy_cert_root}" -path "*/${TURN_REALM}/${TURN_REALM}.key" -print -quit)
  fi

  if [ -n "${cert_file}" ] && [ -n "${key_file}" ]; then
    printf '%s\n%s\n' "${cert_file}" "${key_file}"
  fi
}

wait_for_tls_files() {
  elapsed=0
  interval=5
  timeout=300

  while [ "${elapsed}" -le "${timeout}" ]; do
    tls_files=$(discover_tls_files)
    if [ -n "${tls_files}" ]; then
      printf '%s\n' "${tls_files}"
      return 0
    fi

    if [ "${elapsed}" -eq "${timeout}" ]; then
      break
    fi

    echo "Waiting for Caddy certificate files for ${TURN_REALM} in ${caddy_cert_root}..." >&2
    sleep "${interval}"
    elapsed=$((elapsed + interval))
  done

  echo "Timed out waiting for Caddy certificate files for ${TURN_REALM} in ${caddy_cert_root}." >&2
  return 1
}

escape_toml_string() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[&|]/\\&/g'
}

render_value() {
  escape_sed_replacement "$(escape_toml_string "$1")"
}

tls_files=$(wait_for_tls_files)
tls_cert_file=$(printf '%s\n' "${tls_files}" | sed -n '1p')
tls_key_file=$(printf '%s\n' "${tls_files}" | sed -n '2p')

sed \
  -e "s|__TURN_REALM__|$(render_value "${TURN_REALM}")|g" \
  -e "s|__TURN_SHARED_SECRET__|$(render_value "${TURN_SHARED_SECRET}")|g" \
  -e "s|__EXTERNAL_IP__|$(render_value "${EXTERNAL_IP}")|g" \
  -e "s|__TLS_CERT_FILE__|$(render_value "${tls_cert_file}")|g" \
  -e "s|__TLS_KEY_FILE__|$(render_value "${tls_key_file}")|g" \
  "${conf_template}" > "${conf_rendered}"

exec turn-server --config="${conf_rendered}"
