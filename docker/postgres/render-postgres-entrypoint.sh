#!/usr/bin/env bash
set -Eeuo pipefail

: "${PGDATA:=/var/lib/postgresql/18/docker}"
export PGDATA

create_self_signed_cert() {
  local ssl_dir="${POSTGRES_SSL_DIR:-/data}"
  local cert_file="${POSTGRES_SSL_CERT_FILE:-$ssl_dir/server.crt}"
  local key_file="${POSTGRES_SSL_KEY_FILE:-$ssl_dir/server.key}"

  mkdir -p "$ssl_dir"

  if [[ -f "$cert_file" && -f "$key_file" ]]; then
    return 0
  fi

  umask 077
  openssl req -new -x509 -days 3650 -nodes \
    -subj "/CN=${POSTGRES_SSL_COMMON_NAME:-postgres}" \
    -keyout "$key_file" \
    -out "$cert_file"

  chmod 600 "$key_file"
  chmod 644 "$cert_file"

  if [[ "$(id -u)" = "0" ]]; then
    chown postgres:postgres "$key_file" "$cert_file"
  fi
}

create_self_signed_cert

exec docker-entrypoint.sh "$@"
