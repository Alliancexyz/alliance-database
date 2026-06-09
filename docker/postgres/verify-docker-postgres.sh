#!/usr/bin/env bash
set -Eeuo pipefail

: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"

export PGPASSWORD="$POSTGRES_PASSWORD"

psql \
  --host "${POSTGRES_HOST:-alliance-postgres-18}" \
  --port "${POSTGRES_PORT:-10000}" \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  -v ON_ERROR_STOP=1 \
  --file /usr/local/share/alliance/docker-readiness.sql
