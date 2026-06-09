#!/bin/sh
set -eu

: "${NGROK_AUTHTOKEN:?NGROK_AUTHTOKEN is required}"
: "${NGROK_TCP_URL:?NGROK_TCP_URL is required}"

NGROK_UPSTREAM="${NGROK_UPSTREAM:-alliance-postgres-18:10000}"
export NGROK_AUTHTOKEN

exec ngrok tcp "$NGROK_UPSTREAM" --url "$NGROK_TCP_URL"
