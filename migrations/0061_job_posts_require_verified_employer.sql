-- Migration 0061 — Employers may post jobs only after an admin approved their
-- employer verification (T-0171, owner decision 2026-11-20).
--
-- OWNER DECISION 2026-11-20 ("ever approved"): once an admin has approved an
-- employer, they KEEP posting rights even if they later edit their documents
-- (the 0053 trigger then sends the record back to 'pending' for admin
-- re-review; that re-review does not block posting).
--
-- Source of truth: new column public.employer_verifications.first_verified_at
-- (timestamptz, null = never approved). A trigger stamps it when the status
-- becomes 'verified' and it is still null. API users (anon/authenticated) can
-- never set, change or clear it: only service role / postgres can.
-- Backfill: rows currently 'verified' get now().
--
-- ADMIN REVOCATION: an admin revokes posting rights explicitly by clearing it:
--   update public.employer_verifications set first_verified_at = null
--   where user_id = '<employer uuid>';       -- as service role / postgres
-- A later admin rejection of a re-submission does NOT revoke it. Clearing it
-- while status stays 'verified' sticks (the stamp only happens on a change of
-- status to 'verified'); to re-grant, set it to now() or re-approve.
--
-- Effect:
--   * INSERT on job_posts as an API user (authenticated) needs
--       auth.uid() = client_id AND first_verified_at is not null.
--   * service_role / postgres bypass RLS: unaffected (admin tooling, seeds).
--   * Existing rows are untouched. UPDATE / DELETE / SELECT policies unchanged,
--     so employers can still manage the jobs they already have.
--
-- RLS policies are permissive (OR-ed). This replaces the one INSERT policy
-- from supabase_schema.sql. If production has an extra permissive INSERT policy
-- on job_posts (dashboard edit), the gate would be bypassed: check with
--   select policyname, cmd from pg_policies where tablename = 'job_posts';
--
-- DEPENDENCY / APPLY ORDER: requires 0053 (HOTFIX A) applied first. The 0043
-- RLS policies on employer_verifications do not restrict `status`, so without
-- the 0053 trigger `employer_verification_force_pending` an employer could
-- write 'verified' for themselves and pass this gate. 0053 is already on
-- production (verified 2026-11-19). This migration refuses to run without it.
--   apply order: 0053 -> 0061
--
-- PRE-CHECK (run first, expect only the policies you know about; any extra
-- permissive INSERT policy on job_posts would bypass the gate):
--   select policyname, cmd, with_check from pg_policies
--   where schemaname = 'public' and tablename = 'job_posts';
-- Rollback: migrations/rollback/0061_job_posts_require_verified_employer_down.sql
begin;

do $$
begin
  if not exists (
    select 1
    from pg_trigger t
    where t.tgname = 'employer_verification_force_pending'
      and t.tgrelid = 'public.employer_verifications'::regclass
      and not t.tgisinternal
  ) then
    raise exception
      '0061 needs migration 0053 first: trigger employer_verification_force_pending is missing on public.employer_verifications';
  end if;
end $$;

-- ---------------------------------------------------------------------
-- first_verified_at: server-owned "ever approved" marker.
-- ---------------------------------------------------------------------
alter table public.employer_verifications
  add column if not exists first_verified_at timestamptz;

comment on column public.employer_verifications.first_verified_at is
  'Set when an admin first approved this employer (status -> verified). Not null = may post jobs, even if later re-submitted/pending. Only service role can change or clear it (admin revocation).';

create or replace function public.employer_verification_stamp_first_verified()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if current_user in ('anon', 'authenticated') then
    -- API users cannot touch the marker.
    if tg_op = 'INSERT' then
      new.first_verified_at := null;
    else
      new.first_verified_at := old.first_verified_at;
    end if;
  elsif new.first_verified_at is null
        and new.status = 'verified'
        and (tg_op = 'INSERT' or old.status is distinct from 'verified') then
    -- Admin / service role approval: first time only.
    new.first_verified_at := now();
  end if;
  return new;
end;
$$;

revoke all on function public.employer_verification_stamp_first_verified()
  from public, anon, authenticated;

drop trigger if exists employer_verification_stamp_first_verified
  on public.employer_verifications;
create trigger employer_verification_stamp_first_verified
  before insert or update on public.employer_verifications
  for each row execute function public.employer_verification_stamp_first_verified();

-- Backfill: everyone currently approved keeps posting rights.
update public.employer_verifications
set first_verified_at = now()
where status = 'verified' and first_verified_at is null;

drop policy if exists "Clients can create job posts" on public.job_posts;
create policy "Clients can create job posts"
  on public.job_posts
  for insert
  with check (
    auth.uid() = client_id
    and exists (
      select 1
      from public.employer_verifications ev
      where ev.user_id = auth.uid()
        and ev.first_verified_at is not null
    )
  );

commit;
