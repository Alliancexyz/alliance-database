-- Readiness checks for Render Postgres service dpg-d8jgjus8aovs739bmrjg-a
-- Database: alliance_test
-- Expected owner/app role: alliance_test_user
-- Run as a role with catalog visibility after Render support has enabled logical replication.
-- This script is read-only.

\echo '== Server logical replication settings =='
SELECT
  name,
  setting,
  unit,
  context,
  pending_restart
FROM pg_settings
WHERE name IN ('wal_level', 'max_wal_senders', 'max_replication_slots')
ORDER BY name;

\echo '== Current database and recovery state =='
SELECT
  current_database() AS database_name,
  current_user AS current_user,
  session_user AS session_user,
  pg_is_in_recovery() AS is_in_recovery;

\echo '== Current role flags =='
SELECT
  rolname,
  rolsuper,
  rolreplication,
  rolcreatedb,
  rolcreaterole,
  rolcanlogin
FROM pg_roles
WHERE rolname = current_user;

\echo '== Expected connection roles =='
SELECT
  expected.rolname AS role_name,
  r.rolsuper,
  r.rolreplication,
  r.rolcreatedb,
  r.rolcreaterole,
  r.rolcanlogin
FROM (VALUES ('alliance_test_user'), ('ardent_replication')) AS expected(rolname)
LEFT JOIN pg_roles r ON r.rolname = expected.rolname
ORDER BY expected.rolname;

\echo '== Existing publications =='
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

\echo '== Existing replication slots =='
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

\echo '== ardent_replication role existence check =='
SELECT EXISTS (
  SELECT 1
  FROM pg_roles
  WHERE rolname = 'ardent_replication'
) AS ardent_replication_exists;

\echo '== Public schema access for expected roles =='
SELECT
  role_name,
  has_database_privilege(role_name, 'alliance_test', 'CONNECT') AS can_connect_database,
  has_database_privilege(role_name, 'alliance_test', 'CREATE') AS can_create_database_objects,
  has_schema_privilege(role_name, 'public', 'USAGE') AS can_use_public_schema,
  has_schema_privilege(role_name, 'public', 'CREATE') AS can_create_in_public_schema
FROM (VALUES ('alliance_test_user'), ('ardent_replication')) AS roles(role_name)
ORDER BY role_name;
