#!/usr/bin/env bash
set -Eeuo pipefail

: "${BEMI_REPLICATION_PASSWORD:?BEMI_REPLICATION_PASSWORD is required}"
: "${ARDENT_REPLICATION_PASSWORD:?ARDENT_REPLICATION_PASSWORD is required}"

psql --username "${POSTGRES_USER:-postgres}" --dbname "${POSTGRES_DB:-${POSTGRES_USER:-postgres}}" \
  -v ON_ERROR_STOP=1 \
  -v db_name="${POSTGRES_DB:-${POSTGRES_USER:-postgres}}" \
  -v app_role="${POSTGRES_USER:-postgres}" \
  -v bemi_password="$BEMI_REPLICATION_PASSWORD" \
  -v ardent_password="$ARDENT_REPLICATION_PASSWORD" <<'SQL'
SELECT format(
  'CREATE ROLE %I LOGIN REPLICATION NOSUPERUSER PASSWORD %L',
  'bemi_replication',
  :'bemi_password'
)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_roles WHERE rolname = 'bemi_replication'
)
\gexec

ALTER ROLE bemi_replication WITH LOGIN REPLICATION NOSUPERUSER PASSWORD :'bemi_password';

SELECT format(
  'CREATE ROLE %I LOGIN REPLICATION SUPERUSER PASSWORD %L',
  'ardent_replication',
  :'ardent_password'
)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_roles WHERE rolname = 'ardent_replication'
)
\gexec

ALTER ROLE ardent_replication WITH LOGIN REPLICATION SUPERUSER PASSWORD :'ardent_password';

GRANT CONNECT ON DATABASE :"db_name" TO bemi_replication, ardent_replication;
GRANT CREATE ON DATABASE :"db_name" TO ardent_replication;


GRANT USAGE ON SCHEMA public TO bemi_replication, ardent_replication;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO bemi_replication, ardent_replication;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO bemi_replication, ardent_replication;
ALTER DEFAULT PRIVILEGES FOR ROLE :"app_role" IN SCHEMA public
  GRANT SELECT ON TABLES TO bemi_replication, ardent_replication;
ALTER DEFAULT PRIVILEGES FOR ROLE :"app_role" IN SCHEMA public
  GRANT SELECT ON SEQUENCES TO bemi_replication, ardent_replication;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'bemi') THEN
    EXECUTE 'CREATE PUBLICATION bemi FOR ALL TABLES';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'dbz_publication') THEN
    EXECUTE 'CREATE PUBLICATION dbz_publication FOR ALL TABLES';
  END IF;
END
$$;
SQL
