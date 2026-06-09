-- Post-support bootstrap for Render Postgres service dpg-d8jgjus8aovs739bmrjg-a
-- Database: alliance_test
-- Owner/app role: alliance_test_user
-- Ardent connection role: ardent_replication
--
-- Run only after Render support has enabled logical replication and granted any
-- required managed-service permissions. This script intentionally does NOT try
-- to grant SUPERUSER or REPLICATION; those privileges are not self-service on
-- Render Managed Postgres and must be handled by Render support.
--
-- Before running, replace the placeholder below with the Ardent-provided password.
-- Do not commit a real password.

\set ardent_replication_password '<FILL_WITH_ARDENT_REPLICATION_PASSWORD>'

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_roles
    WHERE rolname = 'ardent_replication'
  ) THEN
    CREATE ROLE ardent_replication LOGIN;
  END IF;
END
$$;

ALTER ROLE ardent_replication
  WITH LOGIN
  PASSWORD :'ardent_replication_password';

GRANT CONNECT, CREATE ON DATABASE alliance_test TO ardent_replication;
GRANT USAGE ON SCHEMA public TO ardent_replication;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ardent_replication;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO ardent_replication;

ALTER DEFAULT PRIVILEGES FOR ROLE alliance_test_user IN SCHEMA public
  GRANT SELECT ON TABLES TO ardent_replication;

ALTER DEFAULT PRIVILEGES FOR ROLE alliance_test_user IN SCHEMA public
  GRANT SELECT ON SEQUENCES TO ardent_replication;

COMMIT;

-- Bemi table preparation
-- ----------------------
-- Bemi recommends REPLICA IDENTITY FULL for tables it tracks when update/delete
-- events need complete previous row values. Apply this only to concrete tracked
-- tables after the tracked table list is confirmed.
--
-- Example, replace with real tracked tables before running:
-- ALTER TABLE public.<tracked_table_1> REPLICA IDENTITY FULL;
-- ALTER TABLE public.<tracked_table_2> REPLICA IDENTITY FULL;
-- ALTER TABLE public.<tracked_table_3> REPLICA IDENTITY FULL;

-- Bemi publication
-- ----------------
-- Do not create or alter the Bemi publication here unless Render support confirms
-- the managed role has the needed logical replication permissions. Request support
-- to grant REPLICATION to the Bemi connection role and create/confirm the required
-- publication on schema public for Bemi-tracked tables.

-- Ardent logical decoding
-- -----------------------
-- Ardent requires wal2json and SUPERUSER/REPLICATION-level capabilities that are
-- not self-service on Render Managed Postgres. Do not attempt:
--   ALTER ROLE ardent_replication WITH REPLICATION;
--   ALTER ROLE ardent_replication WITH SUPERUSER;
--   CREATE EXTENSION wal2json;
-- Render support must confirm/enable wal2json and grant the required managed
-- permissions for the ardent_replication role.
