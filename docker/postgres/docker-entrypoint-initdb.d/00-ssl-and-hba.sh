#!/usr/bin/env bash
set -Eeuo pipefail

: "${PGDATA:=/var/lib/postgresql/18/docker}"
export PGDATA

ssl_dir="${POSTGRES_SSL_DIR:-/data}"
cert_file="${POSTGRES_SSL_CERT_FILE:-$ssl_dir/server.crt}"
key_file="${POSTGRES_SSL_KEY_FILE:-$ssl_dir/server.key}"

mkdir -p "$ssl_dir"

if [[ ! -f "$cert_file" || ! -f "$key_file" ]]; then
  umask 077
  openssl req -new -x509 -days 3650 -nodes \
    -subj "/CN=${POSTGRES_SSL_COMMON_NAME:-postgres}" \
    -keyout "$key_file" \
    -out "$cert_file"
fi

chmod 600 "$key_file"
chmod 644 "$cert_file"
chown postgres:postgres "$key_file" "$cert_file"

postgresql_conf="$PGDATA/postgresql.conf"
pg_hba_conf="$PGDATA/pg_hba.conf"

append_conf_if_missing() {
  local key="$1"
  local value="$2"

  if ! grep -Eq "^[[:space:]]*${key}[[:space:]]*=" "$postgresql_conf"; then
    printf '%s = %s\n' "$key" "$value" >> "$postgresql_conf"
  fi
}

append_conf_if_missing ssl "on"
append_conf_if_missing ssl_cert_file "'$cert_file'"
append_conf_if_missing ssl_key_file "'$key_file'"
append_conf_if_missing wal_level "logical"
append_conf_if_missing max_wal_senders "10"
append_conf_if_missing max_replication_slots "10"

replication_hba='hostssl replication all all scram-sha-256'
if ! grep -Fqx "$replication_hba" "$pg_hba_conf"; then
  printf '%s\n' "$replication_hba" >> "$pg_hba_conf"
fi
