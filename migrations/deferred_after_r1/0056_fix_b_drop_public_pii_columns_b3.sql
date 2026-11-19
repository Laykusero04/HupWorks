-- ============================================================================
-- Migration 0056 — FIX B, step B3 (T-0128). IRREVERSIBLE (only from backup).
--
-- !!  APPLY ONLY AFTER 0055 (B2) HAS BEEN LIVE AND STABLE, and after the
-- !!  minimum build (0057) has been raised, so no build that still writes
-- !!  seller_profiles.address / birth_* is in use (such writes would fail
-- !!  once the columns are gone).
-- !!  Take a backup / confirm PITR first.
--
-- Step 0 creates missing private rows, step 1 copies anything still only present in the public columns into the
-- owner-only table seller_private_details (never overwrites existing values),
-- step 2 drops the public copies.
-- ============================================================================

begin;

-- Step 0: make sure every seller with a seller_profiles row has a private row
-- to copy into (older sellers / backfill gaps), carrying over what the public
-- columns hold. Valid dates only; invalid ones are caught by the pre-check.
insert into public.seller_private_details (user_id, street_address)
select sp.user_id, nullif(trim(coalesce(sp.address, '')), '')
from public.seller_profiles sp
where not exists (
  select 1 from public.seller_private_details pd where pd.user_id = sp.user_id
)
on conflict (user_id) do nothing;

-- Row by row so one impossible date (e.g. 31 Feb) cannot abort the migration.
do $$
declare
  r record;
begin
  for r in
    select pd.user_id, sp.birth_year y, sp.birth_month m, sp.birth_day d
    from public.seller_private_details pd
    join public.seller_profiles sp on sp.user_id = pd.user_id
    where pd.date_of_birth is null
      and sp.birth_year is not null
      and sp.birth_month is not null
      and sp.birth_day is not null
  loop
    begin
      update public.seller_private_details
      set date_of_birth = make_date(r.y, r.m, r.d), updated_at = now()
      where user_id = r.user_id;
    exception when others then
      raise warning 'B3: skipped invalid birth date for user %', r.user_id;
    end;
  end loop;
end $$;

update public.seller_private_details pd
set street_address = sp.address,
    updated_at = now()
from public.seller_profiles sp
where sp.user_id = pd.user_id
  and (pd.street_address is null or trim(pd.street_address) = '')
  and sp.address is not null
  and trim(sp.address) <> '';

-- Pre-check: abort (and roll back everything above) if any public value would
-- still be lost by the drop, e.g. an impossible birth date such as 31 Feb.
do $$
declare
  v_dob int;
  v_addr int;
begin
  select count(*) into v_dob
  from public.seller_profiles sp
  left join public.seller_private_details pd on pd.user_id = sp.user_id
  where sp.birth_year is not null and sp.birth_month is not null and sp.birth_day is not null
    and pd.date_of_birth is null;

  select count(*) into v_addr
  from public.seller_profiles sp
  left join public.seller_private_details pd on pd.user_id = sp.user_id
  where nullif(trim(coalesce(sp.address, '')), '') is not null
    and nullif(trim(coalesce(pd.street_address, '')), '') is null;

  if v_dob > 0 or v_addr > 0 then
    raise exception 'B3 aborted, nothing dropped: % date(s) of birth and % address(es) exist only in seller_profiles. Inspect them first.',
      v_dob, v_addr;
  end if;
end $$;

alter table public.seller_profiles
  drop column if exists birth_year,
  drop column if exists birth_month,
  drop column if exists birth_day,
  drop column if exists address;

commit;
