-- Tests for migration 0060 (user_private_details). A failure raises an exception.
begin;

do $$
declare a uuid := gen_random_uuid(); b uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, raw_user_meta_data)
    values (a, 'pd-a@example.test', '{"role":"client","name":"PD A"}'::jsonb);
  insert into auth.users (id, email, raw_user_meta_data)
    values (b, 'pd-b@example.test', '{"role":"seller","name":"PD B"}'::jsonb);
  perform set_config('test.a', a::text, true);
  perform set_config('test.b', b::text, true);

  -- signup trigger must NOT create a private row (lazy creation by the app)
  if exists (select 1 from public.user_private_details) then
    raise exception 'FAIL handle_new_user created a private row';
  end if;
end $$;

-- B's row inserted as postgres (fixture)
insert into public.user_private_details (user_id, legal_name, date_of_birth, street_address, postal_code)
values (current_setting('test.b')::uuid, 'Bea Bee', '1990-01-01', 'Straat 1', '2311 AB');

-- anon: no access at all
set local role anon;
do $$
begin
  begin
    perform 1 from public.user_private_details;
    raise exception 'FAIL anon could select';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.user_private_details (user_id) values (gen_random_uuid());
    raise exception 'FAIL anon could insert';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- user A
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.a'), 'role', 'authenticated')::text, true);
do $$
declare a uuid := current_setting('test.a')::uuid; b uuid := current_setting('test.b')::uuid;
        n bigint; before_ts timestamptz; after_ts timestamptz;
begin
  -- cannot see B
  if exists (select 1 from public.user_private_details where user_id = b) then
    raise exception 'FAIL A can read B row';
  end if;

  -- cannot insert for B (RLS with check -> 42501, never a unique violation leak)
  begin
    insert into public.user_private_details (user_id, legal_name) values (b, 'x');
    raise exception 'FAIL A inserted a row for B';
  exception when insufficient_privilege then null;
  end;

  -- own insert OK
  insert into public.user_private_details
    (user_id, legal_name, date_of_birth, street_address, postal_code, consent_version, consented_at)
  values (a, 'Ann Aye', '2000-02-29', 'Laan 2', '1234 ab', 'privacy-2026-11', now());
  if (select count(*) from public.user_private_details) <> 1 then
    raise exception 'FAIL A should see exactly own row';
  end if;

  -- own update OK, updated_at moves
  select updated_at into before_ts from public.user_private_details where user_id = a;
  perform pg_sleep(0.01);
  update public.user_private_details set street_address = 'Laan 3' where user_id = a;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL A could not update own row'; end if;
  select updated_at into after_ts from public.user_private_details where user_id = a;
  if after_ts <= before_ts then raise exception 'FAIL updated_at trigger did not fire'; end if;

  -- cannot update B (0 rows) and cannot move own row to B
  update public.user_private_details set legal_name = 'hacked' where user_id = b;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL A updated B row'; end if;
  begin
    update public.user_private_details set user_id = b where user_id = a;
    raise exception 'FAIL A re-pointed row to B';
  exception when insufficient_privilege then null;
  end;

  -- no delete (no grant)
  begin
    delete from public.user_private_details where user_id = a;
    raise exception 'FAIL A could delete';
  exception when insufficient_privilege then null;
  end;

  -- upsert style (on conflict) on own row
  insert into public.user_private_details (user_id, legal_name) values (a, 'Ann Two')
    on conflict (user_id) do update set legal_name = excluded.legal_name;
  if (select legal_name from public.user_private_details where user_id = a) <> 'Ann Two' then
    raise exception 'FAIL own upsert did not update';
  end if;
end $$;
reset role;

-- CHECK constraints (as postgres)
do $$
declare a uuid := current_setting('test.a')::uuid;
        too_young date := ((now() at time zone 'utc')::date - interval '16 years')::date + 1;
        exactly_16 date := ((now() at time zone 'utc')::date - interval '16 years')::date;
begin
  begin
    update public.user_private_details set date_of_birth = too_young where user_id = a;
    raise exception 'FAIL 15y364d accepted';
  exception when check_violation then null; end;
  update public.user_private_details set date_of_birth = exactly_16 where user_id = a;
  begin
    update public.user_private_details set date_of_birth = '1850-01-01' where user_id = a;
    raise exception 'FAIL 1850 accepted';
  exception when check_violation then null; end;
  begin
    update public.user_private_details set postal_code = '0123 AB' where user_id = a;
    raise exception 'FAIL postal starting with 0 accepted';
  exception when check_violation then null; end;
  update public.user_private_details set postal_code = '1234AB' where user_id = a;
  begin
    update public.user_private_details set postal_code = '12345' where user_id = a;
    raise exception 'FAIL bad postal accepted';
  exception when check_violation then null; end;
  -- consent pair can no longer be broken: trigger nulls consented_at with the version
  update public.user_private_details set consent_version = null where user_id = a;
  if (select consented_at from public.user_private_details where user_id = a) is not null then
    raise exception 'FAIL consented_at kept after consent_version cleared';
  end if;
  update public.user_private_details set consent_version = 'privacy-2026-11', consented_at = '2001-01-01Z' where user_id = a;
  if (select consented_at from public.user_private_details where user_id = a) < now() - interval '1 minute' then
    raise exception 'FAIL client-supplied consented_at used';
  end if;
  begin
    update public.user_private_details set legal_name = '   ' where user_id = a;
    raise exception 'FAIL blank legal_name accepted';
  exception when check_violation then null; end;
  begin
    update public.user_private_details set legal_name = repeat('x', 201) where user_id = a;
    raise exception 'FAIL long legal_name accepted';
  exception when check_violation then null; end;
end $$;

-- Consent proof is server-side; created_at is immutable; age basis is UTC
do $$
declare a uuid := current_setting('test.a')::uuid; c0 timestamptz;
        utc_today date := (now() at time zone 'utc')::date;
begin
  select created_at into c0 from public.user_private_details where user_id = a;
  update public.user_private_details set created_at = '2000-01-01Z' where user_id = a;
  if (select created_at from public.user_private_details where user_id = a) <> c0 then
    raise exception 'FAIL created_at changed';
  end if;
  -- session timezone far ahead of UTC must not change the age basis
  set local timezone = 'Pacific/Kiritimati';
  update public.user_private_details set date_of_birth = (utc_today - interval '16 years')::date where user_id = a;
  begin
    update public.user_private_details set date_of_birth = (utc_today - interval '16 years')::date + 1 where user_id = a;
    raise exception 'FAIL age basis follows session timezone';
  exception when check_violation then null; end;
  set local timezone = 'Pacific/Pago_Pago';
  update public.user_private_details set date_of_birth = (utc_today - interval '16 years')::date where user_id = a;
  reset timezone;
end $$;

-- Not exposed anywhere: no view, no realtime publication, no stray function
do $$
begin
  if exists (
    select 1 from information_schema.view_table_usage
    where table_schema = 'public' and table_name = 'user_private_details'
      and view_name <> 'seller_public_age') then
    raise exception 'FAIL a view other than seller_public_age reads user_private_details';
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name in ('profiles','seller_profiles','my_profile','my_seller_profile','seller_public_age')
      and column_name in ('legal_name','consent_version','consented_at')) then
    raise exception 'FAIL private column present on a profile table/view';
  end if;
  if exists (select 1 from pg_publication_tables
             where schemaname = 'public' and tablename = 'user_private_details') then
    raise exception 'FAIL table is in a realtime publication';
  end if;
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prosrc ilike '%user_private_details%'
      and p.proname not in ('delete_own_account', 'trg_user_private_details_updated_at')) then
    raise exception 'FAIL an unexpected function references user_private_details';
  end if;
  if not exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='public' and p.proname='trg_user_private_details_updated_at'
      and p.proconfig @> array['search_path=public, pg_temp']) then
    raise exception 'FAIL trigger function search_path not pinned';
  end if;
  if has_table_privilege('anon', 'public.user_private_details', 'select')
     or has_table_privilege('authenticated', 'public.user_private_details', 'delete')
     or has_table_privilege('authenticated', 'public.user_private_details', 'truncate') then
    raise exception 'FAIL excess privileges';
  end if;
end $$;

-- delete_own_account removes A's private row; B untouched
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.a'), 'role', 'authenticated')::text, true);
select public.delete_own_account();
reset role;

do $$
begin
  if exists (select 1 from public.user_private_details
              where user_id = current_setting('test.a')::uuid) then
    raise exception 'FAIL private row survived delete_own_account';
  end if;
  if not exists (select 1 from public.user_private_details
                  where user_id = current_setting('test.b')::uuid) then
    raise exception 'FAIL B row lost';
  end if;
  -- FK cascade alone also works (admin path)
  delete from auth.users where id = current_setting('test.b')::uuid;
  if exists (select 1 from public.user_private_details) then
    raise exception 'FAIL cascade from auth.users did not remove row';
  end if;
end $$;

rollback;
