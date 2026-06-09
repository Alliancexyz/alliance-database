-- Readiness checks for the self-managed PostgreSQL 18 Docker service on Render.
-- Database: alliance_test
-- Expected roles: alliance_test_user, bemi_replication, ardent_replication
-- Run as the self-managed superuser or a role with replication privileges.

\echo '== WAL and logical replication settings =='
SELECT
  name,
  setting,
  unit,
  context,
  pending_restart
FROM pg_settings
WHERE name IN (
  'wal_level',
  'max_wal_senders',
  'max_replication_slots',
  'max_slot_wal_keep_size',
  'wal_keep_size'
)
ORDER BY name;

\echo '== Database, session, and recovery state =='
SELECT
  current_database() AS database_name,
  current_user AS current_user,
  session_user AS session_user,
  pg_is_in_recovery() AS is_in_recovery;

\echo '== Expected role flags =='
SELECT
  expected.rolname AS role_name,
  r.rolsuper,
  r.rolreplication,
  r.rolcreatedb,
  r.rolcreaterole,
  r.rolcanlogin,
  r.rolbypassrls
FROM (
  VALUES
    ('alliance_test_user'),
    ('bemi_replication'),
    ('ardent_replication')
) AS expected(rolname)
LEFT JOIN pg_roles r ON r.rolname = expected.rolname
ORDER BY expected.rolname;

\echo '== Publications =='
SELECT
  pubname,
  pubowner::regrole AS owner,
  puballtables,
  pubinsert,
  pubupdate,
  pubdelete,
  pubtruncate,
  pubviaroot
FROM pg_publication
ORDER BY pubname;

\echo '== Publication table membership =='
SELECT
  pubname,
  schemaname,
  tablename
FROM pg_publication_tables
ORDER BY pubname, schemaname, tablename;

\echo '== Replication slots before wal2json probe =='
SELECT
  slot_name,
  plugin,
  slot_type,
  database,
  temporary,
  active,
  active_pid,
  restart_lsn,
  confirmed_flush_lsn,
  wal_status
FROM pg_replication_slots
ORDER BY slot_name;

\echo '== wal2json availability probe =='
DO $$
DECLARE
  probe_exists boolean;
  created_probe boolean := false;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_replication_slots
    WHERE slot_name = 'ardent_probe'
  ) INTO probe_exists;

  IF probe_exists THEN
    RAISE NOTICE 'replication slot ardent_probe already exists; skipping wal2json create/drop probe';
  ELSE
    PERFORM * FROM pg_create_logical_replication_slot('ardent_probe', 'wal2json', true);
    created_probe := true;
    PERFORM pg_drop_replication_slot('ardent_probe');
    created_probe := false;
    RAISE NOTICE 'wal2json probe succeeded; temporary slot ardent_probe created and dropped';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    IF created_probe AND EXISTS (
      SELECT 1
      FROM pg_replication_slots
      WHERE slot_name = 'ardent_probe'
    ) THEN
      BEGIN
        PERFORM pg_drop_replication_slot('ardent_probe');
      EXCEPTION
        WHEN OTHERS THEN
          RAISE WARNING 'cleanup failed for temporary slot ardent_probe: %', SQLERRM;
      END;
    END IF;
    RAISE;
END
$$;

\echo '== Replication slots after wal2json probe cleanup =='
SELECT
  slot_name,
  plugin,
  slot_type,
  database,
  temporary,
  active,
  active_pid,
  restart_lsn,
  confirmed_flush_lsn,
  wal_status
FROM pg_replication_slots
ORDER BY slot_name;
