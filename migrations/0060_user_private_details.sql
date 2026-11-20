-- Migration 0060 — user_private_details (T-0172, plan T-0167)
-- Owner-only private personal details for every role (legal name, date of birth,
-- street address, NL postal code, privacy consent proof).
--   * Rows are created lazily by the app (upsert after sign-in). handle_new_user is NOT touched.
--   * RLS: authenticated users can select / insert / update ONLY their own row.
--     No delete policy (rows go via cascade / delete_own_account). Nothing for anon.
--   * Not exposed through any RPC or realtime publication. Never copy these columns
--     into profiles or any public view. ONE exception: the view seller_public_age
--     (0054) now takes the whole-year age from user_private_details.date_of_birth
--     (falling back to seller_private_details), still only when the freelancer
--     turned show_age on. It exposes the age in years, never the date.
--   * Admin reads: service role only, through the admin API; each read must be written
--     to admin_audit_log (0052) as "viewed user X" with NO field values.
-- Needs 0054 (seller_public_age) to be applied already (it is live).
-- Safe to apply before any app release.
begin;

create table if not exists public.user_private_details (
  user_id        uuid primary key references auth.users (id) on delete cascade,
  legal_name     text,
  date_of_birth  date,
  street_address text,
  postal_code    text,
  consent_version text,
  consented_at   timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),

  constraint user_private_details_legal_name_len
    check (legal_name is null or char_length(btrim(legal_name)) between 1 and 200),
  constraint user_private_details_street_len
    check (street_address is null or char_length(btrim(street_address)) between 1 and 300),
  -- NL format: 4 digits (first not 0) + optional space + 2 letters
  constraint user_private_details_postal_nl
    check (postal_code is null or postal_code ~* '^[1-9][0-9]{3} ?[A-Z]{2}$'),
  -- Minimum age 16 (D5), calendar basis = the UTC date (the app uses the same basis,
  -- lib/core/utils/age_check.dart). Also a sanity lower bound.
  constraint user_private_details_dob_min_age
    check (date_of_birth is null
           or (date_of_birth <= ((now() at time zone 'utc')::date - interval '16 years')::date
               and date_of_birth >= date '1900-01-01')),
  constraint user_private_details_consent_pair
    check ((consent_version is null) = (consented_at is null)),
  constraint user_private_details_consent_version_len
    check (consent_version is null or char_length(consent_version) between 1 and 64)
);

comment on table public.user_private_details is
  'Owner-only private personal details (T-0172). Never expose via views/RPC/realtime. Admin reads: service role + admin_audit_log.';

-- Server-side trigger: updated_at, consent proof, immutable created_at.
--   * consented_at is NEVER taken from the client. It is set to the server time
--     whenever consent_version is set or changed, kept when unchanged, and null
--     when consent_version is null.
--   * created_at cannot be changed by updates.
create or replace function public.trg_user_private_details_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    new.consented_at := case when new.consent_version is null then null
                             else clock_timestamp() end;
  else
    new.created_at := old.created_at;
    new.updated_at := clock_timestamp();
    if new.consent_version is null then
      new.consented_at := null;
    elsif new.consent_version is distinct from old.consent_version then
      new.consented_at := clock_timestamp();
    else
      new.consented_at := old.consented_at;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists user_private_details_updated_at on public.user_private_details;
create trigger user_private_details_updated_at
  before insert or update on public.user_private_details
  for each row execute function public.trg_user_private_details_updated_at();

-- RLS
alter table public.user_private_details enable row level security;

drop policy if exists "user_private_details_select_own" on public.user_private_details;
create policy "user_private_details_select_own"
  on public.user_private_details for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "user_private_details_insert_own" on public.user_private_details;
create policy "user_private_details_insert_own"
  on public.user_private_details for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "user_private_details_update_own" on public.user_private_details;
create policy "user_private_details_update_own"
  on public.user_private_details for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Privileges: Supabase default privileges grant everything to anon/authenticated.
revoke all on table public.user_private_details from public;
revoke all on table public.user_private_details from anon;
revoke all on table public.user_private_details from authenticated;
grant select, insert, update on table public.user_private_details to authenticated;
grant all on table public.user_private_details to service_role;

-- delete_own_account: same as 0044 plus an explicit delete of the private row
-- (the FK cascade would also remove it).
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  perform public.prepare_account_deletion(uid);

  delete from public.user_private_details where user_id = uid;

  -- Cascades most marketplace rows (seller_profiles, chat, jobs, etc.).
  delete from public.profiles where id = uid;

  -- Remove Auth identity (also cascades verification tables -> auth.users).
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
grant execute on function public.delete_own_account() to service_role;

-- seller_public_age (0054): same columns, grants, security_barrier and show_age
-- gating. The age now comes from the NEW private date of birth, falling back to
-- the old seller_private_details value for freelancers who have not entered it
-- in the new table yet. Only whole years are exposed, never the date.
create or replace view public.seller_public_age
  with (security_barrier = true) as
  select
    sp.user_id,
    case
      when sp.show_age
        and coalesce(upd.date_of_birth, spd.date_of_birth) is not null
        then date_part('year', age(coalesce(upd.date_of_birth, spd.date_of_birth)))::int
    end as age_years
  from public.seller_profiles sp
  left join public.user_private_details upd on upd.user_id = sp.user_id
  left join public.seller_private_details spd on spd.user_id = sp.user_id;

revoke all on public.seller_public_age from public, anon, authenticated;
grant select on public.seller_public_age to anon, authenticated;

commit;
