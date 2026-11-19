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

## Deferred migrations (T-0128)
`migrations/deferred_after_r1/` (0055 B2, 0056 B3, 0057 min-build) are NOT applied
by `run.sh` (its glob is `migrations/0*.sql`). `tests/zz_0055_fix_b_b2.sql` applies
0055 itself with `\i` (it runs last because 0055 commits). 0056/0057 have no test yet.
Tests added: 0053_protect_profiles_and_ratings.sql, 0054_fix_b_pii_views_b1.sql,
zz_0055_fix_b_b2.sql. All UNRUN (no Docker/psql/Supabase CLI).

## Harness (fix round 2)
`harness/00_supabase_stub.sql` creates anon/authenticated/service_role, an `auth` schema
(users, uid(), role(), jwt()), a minimal `storage` schema and the realtime publication.
`run.sh` applies it only when `auth.users` does not exist (plain Postgres; skipped on
`supabase start`) and sets Supabase-like default privileges on `public` after the schema reset,
so the revoke / column-privilege tests are meaningful. Also `tests/zz_0056_fix_b_b3.sql`.
Still UNRUN.
