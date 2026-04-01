#!/bin/sh
set -eu

conf_source="/etc/coturn/turnserver.conf"
conf_rendered="/tmp/turnserver.conf"

: "${TURN_REALM:?TURN_REALM is required}"
: "${TURN_SHARED_SECRET:?TURN_SHARED_SECRET is required}"

cp "${conf_source}" "${conf_rendered}"

{
  echo
  echo "realm=${TURN_REALM}"
  echo "static-auth-secret=${TURN_SHARED_SECRET}"
} >> "${conf_rendered}"

if [ -n "${TURN_TLS_CERT_FILE:-}" ] && [ -n "${TURN_TLS_KEY_FILE:-}" ]; then
  {
    echo "tls-listening-port=${TURN_TLS_LISTENING_PORT:-5349}"
    echo "cert=${TURN_TLS_CERT_FILE}"
    echo "pkey=${TURN_TLS_KEY_FILE}"
  } >> "${conf_rendered}"
fi

set -- turnserver -n -c "${conf_rendered}"

if [ -n "${EXTERNAL_IP:-}" ]; then
  set -- "$@" --external-ip "${EXTERNAL_IP}"
fi

exec "$@"
