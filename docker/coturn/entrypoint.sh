#!/bin/sh
set -eu

conf_source="/etc/coturn/turnserver.conf"
conf_rendered="/tmp/turnserver.conf"
caddy_cert_root="/caddy-certs/caddy/certificates"

: "${TURN_REALM:?TURN_REALM is required}"
: "${TURN_SHARED_SECRET:?TURN_SHARED_SECRET is required}"

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

tls_files=$(wait_for_tls_files)
tls_cert_file=$(printf '%s\n' "${tls_files}" | sed -n '1p')
tls_key_file=$(printf '%s\n' "${tls_files}" | sed -n '2p')

cp "${conf_source}" "${conf_rendered}"

{
  echo
  echo "realm=${TURN_REALM}"
  echo "static-auth-secret=${TURN_SHARED_SECRET}"
  echo "cert=${tls_cert_file}"
  echo "pkey=${tls_key_file}"
} >> "${conf_rendered}"

set -- turnserver -n -c "${conf_rendered}"

if [ -n "${EXTERNAL_IP:-}" ]; then
  set -- "$@" --external-ip "${EXTERNAL_IP}"
fi

exec "$@"
