-- ============================================
-- Migration 0053 — HOTFIX A (T-0119 / T-0121)
-- Protect server-owned columns on profiles, compute ratings in the database,
-- stop users approving their own verification.
--
-- Safe to apply BEFORE any app release: every write the current app makes
-- still succeeds (rating writes become silent no-ops). Idempotent.
-- Apply order: 0053 first. See company/outputs/engineering/T-0121-T-0128-build-notes.md
-- Rollback: migrations/rollback/0053_protect_profiles_and_ratings_down.sql
--
-- Design: the checks use current_user, not auth.role(). PostgREST runs API
-- calls as role anon/authenticated, so current_user is one of those.
-- SECURITY DEFINER functions (handle_new_user 0036, the verification sync
-- triggers 0034/0043, recalc_profile_rating below) run as their owner and are
-- NOT restricted. The service role / SQL editor are not restricted either.
-- Because of that, the signup trigger handle_new_user is unaffected, and the
-- functions here never raise: they only overwrite NEW values.
-- ============================================

begin;

-- ---------------------------------------------------------------------
-- A1. Pre-flight: look for the production-only trigger that references
-- NEW.chips ("record new has no field chips"). The repo has no such trigger
-- (grep of supabase_schema.sql + migrations 0001-0052 finds no "chips"), so it
-- was created by hand in production. It cannot be fixed from the repo; this
-- block only WARNS so the owner sees it. Fix it with the Part 0 (0a) output:
-- re-create that function without NEW.chips, or drop its trigger.
-- This migration does not touch it and does not depend on it.
-- ---------------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in
    select t.tgname, p.proname
    from pg_trigger t
    join pg_proc p on p.oid = t.tgfoid
    where t.tgrelid = 'public.profiles'::regclass
      and not t.tgisinternal
      and p.prosrc ilike '%chips%'
  loop
    raise warning 'A1: trigger % on public.profiles runs function % which mentions "chips". Fix it manually (Part 0 0a).',
      r.tgname, r.proname;
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- A2. Ratings are calculated by the database from reviews.
-- ---------------------------------------------------------------------
create or replace function public.recalc_profile_rating(p_profile uuid)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  update public.profiles p
  set rating = coalesce((
        select round(avg(r.rating)::numeric, 1)
        from public.reviews r
        where r.reviewed_id = p_profile), 0)
  where p.id = p_profile;
$$;
revoke all on function public.recalc_profile_rating(uuid) from public, anon, authenticated;

create or replace function public.reviews_recalc_rating_trg()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.recalc_profile_rating(new.reviewed_id);
  end if;
  if tg_op = 'DELETE' or (tg_op = 'UPDATE' and old.reviewed_id is distinct from new.reviewed_id) then
    perform public.recalc_profile_rating(old.reviewed_id);
  end if;
  return null;
end;
$$;
revoke all on function public.reviews_recalc_rating_trg() from public, anon, authenticated;

drop trigger if exists reviews_recalc_rating on public.reviews;
create trigger reviews_recalc_rating
  after insert or update or delete on public.reviews
  for each row execute function public.reviews_recalc_rating_trg();

-- ---------------------------------------------------------------------
-- A3. API users cannot set server-owned columns on profiles.
-- Allowed for API users (what the app does today):
--   * INSERT own row at signup with role 'client' or 'seller' (role is kept);
--   * set verification_status / profile_photo_status back to 'pending'
--     with reviewed_at and rejection_reason cleared (resubmission).
-- Everything else on the protected columns is silently reset, so the app's
-- old rating writes become no-ops instead of errors.
-- ---------------------------------------------------------------------
create or replace function public.profiles_protect_columns()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if current_user not in ('anon', 'authenticated') then
    return new;                       -- service role, SQL editor, definer functions
  end if;

  if tg_op = 'INSERT' then
    new.rating  := 0;
    new.balance := 0;
    new.verification_status            := 'unverified';
    new.verification_reviewed_at       := null;
    new.verification_rejection_reason  := null;
    new.profile_photo_status           := 'unverified';
    new.profile_photo_reviewed_at      := null;
    new.profile_photo_rejection_reason := null;
    if nullif(trim(coalesce(new.profile_image_url, '')), '') is not null then
      new.profile_photo_status := 'pending';   -- a photo set at insert still needs review
    end if;
    return new;
  end if;

  -- UPDATE
  new.role    := old.role;
  new.rating  := old.rating;
  new.balance := old.balance;

  if new.verification_status is distinct from old.verification_status
     or new.verification_reviewed_at is distinct from old.verification_reviewed_at
     or new.verification_rejection_reason is distinct from old.verification_rejection_reason then
    if new.verification_status = 'pending' then
      new.verification_reviewed_at      := null;
      new.verification_rejection_reason := null;
    else
      new.verification_status           := old.verification_status;
      new.verification_reviewed_at      := old.verification_reviewed_at;
      new.verification_rejection_reason := old.verification_rejection_reason;
    end if;
  end if;

  if new.profile_photo_status is distinct from old.profile_photo_status
     or new.profile_photo_reviewed_at is distinct from old.profile_photo_reviewed_at
     or new.profile_photo_rejection_reason is distinct from old.profile_photo_rejection_reason then
    if new.profile_photo_status = 'pending' then
      new.profile_photo_reviewed_at      := null;
      new.profile_photo_rejection_reason := null;
    else
      new.profile_photo_status           := old.profile_photo_status;
      new.profile_photo_reviewed_at      := old.profile_photo_reviewed_at;
      new.profile_photo_rejection_reason := old.profile_photo_rejection_reason;
    end if;
  end if;

  -- Changing the photo itself always sends it back to review, even if the
  -- caller leaves profile_photo_status untouched (or sets it to 'verified').
  if nullif(trim(coalesce(new.profile_image_url, '')), '') is not null
     and new.profile_image_url is distinct from old.profile_image_url then
    new.profile_photo_status           := 'pending';
    new.profile_photo_reviewed_at      := null;
    new.profile_photo_rejection_reason := null;
  end if;

  return new;
end;
$$;
revoke all on function public.profiles_protect_columns() from public, anon, authenticated;

drop trigger if exists profiles_protect_columns on public.profiles;
create trigger profiles_protect_columns
  before insert or update on public.profiles
  for each row execute function public.profiles_protect_columns();

-- A user may not move their row to another id. Drop + create (not ALTER) so the
-- migration does not fail if the policy was missing in production.
-- If Part 0 (0c) shows a differently named UPDATE policy in production, drop
-- that one as well; two permissive policies with the same condition are harmless.
drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile" on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ---------------------------------------------------------------------
-- A4. API users cannot approve their own verification.
-- The app only ever submits status 'pending'. Admin approval (service role /
-- SQL editor) is unaffected. Closes the path where a user writes
-- status = 'verified' and the definer sync trigger copies it to profiles.
-- ---------------------------------------------------------------------
create or replace function public.verification_force_pending()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if current_user in ('anon', 'authenticated') then
    new.status           := 'pending';
    new.reviewed_at      := null;
    new.rejection_reason := null;
  end if;
  return new;
end;
$$;

revoke all on function public.verification_force_pending() from public, anon, authenticated;

drop trigger if exists seller_identity_force_pending on public.seller_identity_verifications;
create trigger seller_identity_force_pending
  before insert or update on public.seller_identity_verifications
  for each row execute function public.verification_force_pending();

drop trigger if exists employer_verification_force_pending on public.employer_verifications;
create trigger employer_verification_force_pending
  before insert or update on public.employer_verifications
  for each row execute function public.verification_force_pending();

-- ---------------------------------------------------------------------
-- A5. One-off backfill: every rating = average of its reviews.
-- (Runs as the migration owner, so A3 does not block it.)
-- ---------------------------------------------------------------------
update public.profiles p
set rating = coalesce(r.avg_rating, 0)
from (
  select pr.id, round(avg(rv.rating)::numeric, 1) as avg_rating
  from public.profiles pr
  left join public.reviews rv on rv.reviewed_id = pr.id
  group by pr.id
) r
where r.id = p.id
  and p.rating is distinct from coalesce(r.avg_rating, 0);

commit;

-- NOT included on purpose (decide after the abuse queries, 02_abuse_detection):
--   * resetting balances / verification statuses that look tampered;
--   * any change to read access (that is FIX B, migrations 0054+).
