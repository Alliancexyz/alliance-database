#!/bin/sh
set -eu

: "${NGROK_AUTHTOKEN:?NGROK_AUTHTOKEN is required}"

NGROK_UPSTREAM="${NGROK_UPSTREAM:-alliance-postgres-18:10000}"
export NGROK_AUTHTOKEN

if [ -n "${NGROK_TCP_URL:-}" ]; then
  exec ngrok tcp "$NGROK_UPSTREAM" --url "$NGROK_TCP_URL"
fi

exec ngrok tcp "$NGROK_UPSTREAM"
