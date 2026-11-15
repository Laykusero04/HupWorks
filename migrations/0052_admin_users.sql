-- ============================================
-- Migration 0052 — admin allow-list + admin audit log
-- Used only by the website admin API (service role). The API verifies the
-- caller's JWT and then requires a row in admin_users.
-- No client policies: RLS on, all anon/authenticated access revoked.
-- The first admin is inserted by hand in the SQL editor (owner action):
--   insert into public.admin_users (user_id, note) values ('<auth user uuid>', 'owner');
-- Rollback: migrations/rollback/0052_admin_users_down.sql
-- ============================================

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  note text
);

create table if not exists public.admin_audit_log (
  id bigint generated always as identity primary key,
  admin_id uuid references auth.users (id) on delete set null,
  action text not null,
  target text,
  ip text,
  status text not null default 'success',
  detail jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- status: pending (written before the mutation) | success | failed | rejected.
-- A row left 'pending' means the attempt's outcome is unknown (partial failure).
alter table public.admin_audit_log add column if not exists status text not null default 'success';
alter table public.admin_audit_log add column if not exists detail jsonb not null default '{}'::jsonb;

create index if not exists admin_audit_log_created_at_idx
  on public.admin_audit_log (created_at desc);

alter table public.admin_users enable row level security;
alter table public.admin_audit_log enable row level security;

-- Intentionally no policies: only the service role (bypasses RLS) can access.
revoke all on table public.admin_users from anon, authenticated;
revoke all on table public.admin_audit_log from anon, authenticated;
revoke all on sequence public.admin_audit_log_id_seq from anon, authenticated;

comment on table public.admin_users is
  'Allow-list of auth users permitted to call the admin API. Service role only.';
comment on table public.admin_audit_log is
  'Audit trail of mutating admin API calls. Service role only.';
