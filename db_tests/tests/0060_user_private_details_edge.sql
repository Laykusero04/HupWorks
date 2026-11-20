-- Edge cases for migration 0060 (user_private_details), QA T-0172.
-- Complements db_tests/tests/0060_user_private_details.sql. A failure raises an exception.
-- Local throwaway database only. Everything runs in one transaction and is rolled back.
begin;

-- Fixtures (as the migration owner).
do $$
declare a uuid := gen_random_uuid(); b uuid := gen_random_uuid(); c uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (a, 'pde-a@example.test', '{"role":"client","name":"PDE A"}'::jsonb),
    (b, 'pde-b@example.test', '{"role":"seller","name":"PDE B"}'::jsonb),
    (c, 'pde-c@example.test', '{"role":"client","name":"PDE C"}'::jsonb);
  perform set_config('pde.a', a::text, true);
  perform set_config('pde.b', b::text, true);
  perform set_config('pde.c', c::text, true);
end $$;

insert into public.user_private_details
  (user_id, legal_name, date_of_birth, street_address, postal_code, consent_version, consented_at)
values
  (current_setting('pde.a')::uuid, 'Ann A', '1990-01-01', 'Straat 1', '2311 AB', 'privacy-2026-11', now()),
  (current_setting('pde.b')::uuid, 'Bea B', '1991-01-01', 'Straat 2', '2312 AB', 'privacy-2026-11', now()),
  (current_setting('pde.c')::uuid, 'Cas C', '1992-01-01', 'Straat 3', '2313 AB', null, null);

-- 1. anon: no select, insert, update or delete, even with rows present.
set local role anon;
do $$
begin
  begin
    perform 1 from public.user_private_details;
    raise exception 'FAIL anon could select';
  exception when insufficient_privilege then null; end;
  begin
    update public.user_private_details set legal_name = 'anon';
    raise exception 'FAIL anon could update';
  exception when insufficient_privilege then null; end;
  begin
    delete from public.user_private_details;
    raise exception 'FAIL anon could delete';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- 2. user A sees only A; cannot read, update, insert or delete B.
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pde.a'), 'role', 'authenticated')::text, true);
do $$
declare
  n bigint;
  a uuid := current_setting('pde.a')::uuid;
  b uuid := current_setting('pde.b')::uuid;
begin
  select count(*) into n from public.user_private_details;
  if n <> 1 then raise exception 'FAIL A should see exactly 1 row, saw %', n; end if;

  select count(*) into n from public.user_private_details where user_id = b;
  if n <> 0 then raise exception 'FAIL A can see B by filter'; end if;

  -- RLS hides B's row: no error, zero rows changed.
  update public.user_private_details set legal_name = 'hacked' where user_id = b;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL A updated B row (%)', n; end if;

  begin
    insert into public.user_private_details (user_id, legal_name) values (b, 'fake');
    raise exception 'FAIL A inserted a row for B';
  exception when insufficient_privilege then null; end;

  begin
    delete from public.user_private_details where user_id = b;
    raise exception 'FAIL A could delete B';
  exception when insufficient_privilege then null; end;

  -- A's own row is still there and unchanged by the attempts above.
  if (select legal_name from public.user_private_details where user_id = a) <> 'Ann A' then
    raise exception 'FAIL A own row changed';
  end if;
end $$;
reset role;

-- B's row is untouched (checked as the owner).
do $$
begin
  if (select legal_name from public.user_private_details
       where user_id = current_setting('pde.b')::uuid) <> 'Bea B' then
    raise exception 'FAIL B row was changed by A';
  end if;
end $$;

-- 3. Partial upsert: only postal_code is sent; legal_name and consent stay.
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pde.a'), 'role', 'authenticated')::text, true);
insert into public.user_private_details (user_id, postal_code)
  values (current_setting('pde.a')::uuid, '2311 ab')
  on conflict (user_id) do update set postal_code = excluded.postal_code;
reset role;
do $$
declare r public.user_private_details%rowtype;
begin
  select * into r from public.user_private_details where user_id = current_setting('pde.a')::uuid;
  if r.legal_name <> 'Ann A' or r.consent_version <> 'privacy-2026-11' or r.consented_at is null then
    raise exception 'FAIL partial upsert cleared other columns';
  end if;
  -- The DB stores the value as sent (the regex is case-insensitive); the app normalises to "2311 AB".
  if r.postal_code <> '2311 ab' then raise exception 'FAIL partial upsert postal %', r.postal_code; end if;
end $$;

-- 4. service_role (admin path) sees and updates every row.
set local role service_role;
do $$
declare n bigint;
begin
  select count(*) into n from public.user_private_details;
  if n < 3 then raise exception 'FAIL service_role sees only % rows', n; end if;
  update public.user_private_details set street_address = 'Admin fix'
    where user_id = current_setting('pde.b')::uuid;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL service_role could not update B (%)', n; end if;
end $$;
reset role;

-- 5. Date of birth edges (checks run as the owner, so RLS does not interfere).
do $$
declare
  a uuid := current_setting('pde.a')::uuid;
  exactly_16 date := ((now() at time zone 'utc')::date - interval '16 years')::date;
  tomorrow_16 date := ((now() at time zone 'utc')::date - interval '16 years')::date + 1;
  ok boolean;
begin
  -- Exactly 16 today: accepted.
  update public.user_private_details set date_of_birth = exactly_16 where user_id = a;
  -- 16 tomorrow (one day too young): refused.
  begin
    update public.user_private_details set date_of_birth = tomorrow_16 where user_id = a;
    raise exception 'FAIL dob 16-tomorrow accepted';
  exception when check_violation then null; end;
  -- Leap-day birthday, old enough: accepted.
  update public.user_private_details set date_of_birth = date '2008-02-29' where user_id = a;
  -- Lowest allowed date: accepted.
  update public.user_private_details set date_of_birth = date '1900-01-01' where user_id = a;
  -- Year 1899: refused.
  begin
    update public.user_private_details set date_of_birth = date '1899-12-31' where user_id = a;
    raise exception 'FAIL dob 1899-12-31 accepted';
  exception when check_violation then null; end;
  -- Future date: refused.
  begin
    update public.user_private_details set date_of_birth = (now() at time zone 'utc')::date + 1 where user_id = a;
    raise exception 'FAIL future dob accepted';
  exception when check_violation then null; end;
  -- Put a valid value back.
  update public.user_private_details set date_of_birth = date '1990-01-01' where user_id = a;
end $$;

-- 6. NL postal code edges (regex is ~* with optional single space).
create or replace function pg_temp.pc_ok(v text) returns boolean
language plpgsql as $$
begin
  update public.user_private_details set postal_code = v
    where user_id = current_setting('pde.a')::uuid;
  return true;
exception when check_violation then
  return false;
end $$;

do $$
declare v text;
begin
  foreach v in array array['1234 ab', '1234AB', '9999 zz', '1000 aa'] loop
    if not pg_temp.pc_ok(v) then raise exception 'FAIL postal % refused', v; end if;
  end loop;
  foreach v in array array[
      '0123 AB', '1234  AB', '1234 AB ', ' 1234 AB', E'1234\tAB', '12 34 AB',
      '1234-AB', '1234 A', '123 AB', '12345 AB'] loop
    if pg_temp.pc_ok(v) then raise exception 'FAIL postal % accepted', v; end if;
  end loop;
end $$;

-- 7. Length limits: exact max accepted, one over refused.
do $$
declare a uuid := current_setting('pde.a')::uuid;
begin
  update public.user_private_details set legal_name = repeat('x', 200) where user_id = a;
  begin
    update public.user_private_details set legal_name = repeat('x', 201) where user_id = a;
    raise exception 'FAIL legal_name 201 accepted';
  exception when check_violation then null; end;

  update public.user_private_details set street_address = repeat('y', 300) where user_id = a;
  begin
    update public.user_private_details set street_address = repeat('y', 301) where user_id = a;
    raise exception 'FAIL street 301 accepted';
  exception when check_violation then null; end;

  update public.user_private_details
    set consent_version = repeat('v', 64), consented_at = now() where user_id = a;
  begin
    update public.user_private_details
      set consent_version = repeat('v', 65), consented_at = now() where user_id = a;
    raise exception 'FAIL consent_version 65 accepted';
  exception when check_violation then null; end;
end $$;

-- 8. Consent proof is server-side (fix round 2): client-sent consented_at is ignored.
do $$
declare a uuid := current_setting('pde.a')::uuid; ts1 timestamptz; ts2 timestamptz;
begin
  -- changing consented_at alone keeps the stored value
  select consented_at into ts1 from public.user_private_details where user_id = a;
  update public.user_private_details set consented_at = '2001-01-01Z' where user_id = a;
  select consented_at into ts2 from public.user_private_details where user_id = a;
  if ts2 is distinct from ts1 then raise exception 'FAIL client consented_at accepted on update'; end if;
  -- clearing consent_version clears consented_at (pair stays consistent)
  update public.user_private_details set consent_version = null where user_id = a;
  if (select consented_at from public.user_private_details where user_id = a) is not null then
    raise exception 'FAIL consented_at kept after consent_version cleared';
  end if;
  -- setting consent_version stamps server time, not the client value
  update public.user_private_details
    set consent_version = 'privacy-2026-11', consented_at = '2001-01-01Z' where user_id = a;
  if (select consented_at from public.user_private_details where user_id = a) < now() - interval '1 minute' then
    raise exception 'FAIL client-supplied consented_at used';
  end if;
end $$;

-- 9. delete_own_account removes only the caller's private row (user C).
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('pde.c'), 'role', 'authenticated')::text, true);
select public.delete_own_account();
reset role;
do $$
begin
  if exists (select 1 from public.user_private_details where user_id = current_setting('pde.c')::uuid) then
    raise exception 'FAIL C private row survived delete_own_account';
  end if;
  if not exists (select 1 from public.user_private_details where user_id = current_setting('pde.a')::uuid) then
    raise exception 'FAIL A row removed by C deletion';
  end if;
  if not exists (select 1 from public.user_private_details where user_id = current_setting('pde.b')::uuid) then
    raise exception 'FAIL B row removed by C deletion';
  end if;
end $$;

rollback;
