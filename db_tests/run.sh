#!/usr/bin/env bash
# Local-only DB test runner. NOT RUN YET (needs Docker + Supabase CLI + psql).
set -euo pipefail
cd "$(dirname "$0")/.."

DB_URL="${LOCAL_DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
# Parse the host strictly: scheme://user:pass@HOST:port/db  (no extra '@', '?host=' etc.)
if [[ ! "$DB_URL" =~ ^postgres(ql)?://[^@/?#]*@(127\.0\.0\.1|localhost):[0-9]+/[A-Za-z0-9_]+$ ]]; then
  echo "Refusing to run: LOCAL_DB_URL must be postgresql://user:pass@127.0.0.1|localhost:PORT/DB (no query string)." >&2
  exit 1
fi

psql() { command psql "$DB_URL" -v ON_ERROR_STOP=1 -q "$@"; }

echo "Resetting public schema (local only)..."
# Roles + auth/storage stubs (db_tests/harness) only on a plain Postgres.
# On `supabase start` auth.users already exists and the stub is skipped.
if [[ -z "$(psql -tA -c "select to_regclass('auth.users')")" ]]; then
  echo "No auth schema found: applying db_tests/harness/00_supabase_stub.sql"
  psql -f db_tests/harness/00_supabase_stub.sql
fi
psql -c "drop schema if exists public cascade; create schema public; grant usage on schema public to anon, authenticated, service_role;"
# Supabase-like DEFAULT PRIVILEGES: new tables/sequences/functions in public are
# granted to the API roles. Without this, "revoke ... then grant" and
# "private column not readable" tests would pass trivially. Must run AFTER the
# schema is re-created (dropping the schema drops its default ACLs).
psql -c "alter default privileges in schema public grant all on tables to anon, authenticated, service_role; alter default privileges in schema public grant all on sequences to anon, authenticated, service_role; alter default privileges in schema public grant all on functions to anon, authenticated, service_role;"
psql -f supabase_schema.sql
for f in migrations/0*.sql; do echo "apply $f"; psql -f "$f"; done
for t in db_tests/tests/*.sql; do echo "test  $t"; psql -f "$t"; done
echo "All DB tests passed."
