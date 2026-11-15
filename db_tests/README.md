# db_tests — local database tests

Plain `.sql` tests for migrations, run ONLY against a LOCAL Supabase
(Docker). Never run them against production or a project with real data.

STATUS: scaffold written for T-0142. These tests have NOT been run
(Docker, Supabase CLI and psql were not available when written).

## Prerequisites (not yet installed)
- Docker Desktop
- Supabase CLI (`supabase start` brings up a local Postgres on port 54322)
- psql

## Run (once the prerequisites exist)
    supabase start                      # local stack only
    ./db_tests/run.sh                   # resets the local DB, applies baseline + migrations, runs tests

`run.sh` refuses to run unless the DB host is localhost/127.0.0.1.
It applies `supabase_schema.sql`, then `migrations/00*.sql` in order, then each
`db_tests/tests/*.sql`. A test fails by raising an exception (psql exits non-zero).
Tests run inside a transaction that is rolled back.

Baseline caveat: the repo SQL may differ from production (manual dashboard
edits). Results are "repo-baseline" until a read-only schema dump is provided.

## Writing tests
Simulate a user with:
    set local role authenticated;
    select set_config('request.jwt.claims','{"sub":"<uuid>","role":"authenticated"}', true);
Down scripts live in `migrations/rollback/`.
