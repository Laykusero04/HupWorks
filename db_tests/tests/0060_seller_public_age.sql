-- Tests for migration 0060: seller_public_age now reads the NEW private DOB
-- (user_private_details), falls back to seller_private_details, keeps show_age
-- gating, columns and grants. A failure raises an exception.
begin;

do $$
declare s uuid := gen_random_uuid(); s2 uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, raw_user_meta_data)
    values (s, 'age-seller@example.test', '{"role":"seller","name":"Age Seller"}'::jsonb);
  insert into auth.users (id, email, raw_user_meta_data)
    values (s2, 'age-seller2@example.test', '{"role":"seller","name":"Age Seller 2"}'::jsonb);
  perform set_config('test.s', s::text, true);
  perform set_config('test.s2', s2::text, true);
  -- old table: 1980-01-01, new table: 1995-06-15 (different on purpose)
  update public.seller_private_details set date_of_birth = date '1980-01-01' where user_id = s;
  update public.seller_private_details set date_of_birth = date '1980-01-01' where user_id = s2;
  insert into public.user_private_details (user_id, date_of_birth) values (s, date '1995-06-15');
end $$;

do $$
declare a int; s uuid := current_setting('test.s')::uuid; s2 uuid := current_setting('test.s2')::uuid;
begin
  -- show_age off: null for both, even with DOBs stored
  update public.seller_profiles set show_age = false where user_id in (s, s2);
  select age_years into a from public.seller_public_age where user_id = s;
  if a is not null then raise exception 'FAIL show_age off must give null (new DOB), got %', a; end if;
  select age_years into a from public.seller_public_age where user_id = s2;
  if a is not null then raise exception 'FAIL show_age off must give null (old DOB), got %', a; end if;

  update public.seller_profiles set show_age = true where user_id in (s, s2);

  -- new DOB wins over the old one
  select age_years into a from public.seller_public_age where user_id = s;
  if a is distinct from date_part('year', age(date '1995-06-15'))::int then
    raise exception 'FAIL new DOB must win, got %', a;
  end if;

  -- fallback: no new row, old DOB is used
  select age_years into a from public.seller_public_age where user_id = s2;
  if a is distinct from date_part('year', age(date '1980-01-01'))::int then
    raise exception 'FAIL fallback to seller_private_details, got %', a;
  end if;

  -- new row exists but its DOB is null: fallback again
  insert into public.user_private_details (user_id, legal_name) values (s2, 'No Dob');
  select age_years into a from public.seller_public_age where user_id = s2;
  if a is distinct from date_part('year', age(date '1980-01-01'))::int then
    raise exception 'FAIL null new DOB must fall back, got %', a;
  end if;

  -- no DOB anywhere: null
  update public.seller_private_details set date_of_birth = null where user_id = s2;
  select age_years into a from public.seller_public_age where user_id = s2;
  if a is not null then raise exception 'FAIL no DOB anywhere must give null'; end if;

  update public.seller_profiles set show_age = false where user_id = s;
  select age_years into a from public.seller_public_age where user_id = s;
  if a is not null then raise exception 'FAIL show_age turned off again must give null'; end if;
end $$;

-- Shape and grants unchanged: exactly user_id + age_years, security_barrier,
-- readable by anon/authenticated, nothing else exposed.
do $$
begin
  if (select array_agg(column_name::text order by ordinal_position)
        from information_schema.columns
       where table_schema = 'public' and table_name = 'seller_public_age')
     is distinct from array['user_id', 'age_years'] then
    raise exception 'FAIL seller_public_age columns changed';
  end if;
  if not exists (select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
                 where n.nspname = 'public' and c.relname = 'seller_public_age'
                   and c.reloptions @> array['security_barrier=true']) then
    raise exception 'FAIL seller_public_age lost security_barrier';
  end if;
  if not has_table_privilege('anon', 'public.seller_public_age', 'select')
     or not has_table_privilege('authenticated', 'public.seller_public_age', 'select') then
    raise exception 'FAIL anon/authenticated lost select on seller_public_age';
  end if;
  if has_table_privilege('anon', 'public.seller_public_age', 'insert')
     or has_table_privilege('authenticated', 'public.seller_public_age', 'update') then
    raise exception 'FAIL seller_public_age is writable';
  end if;
end $$;

-- Through the API roles: anon can read the age only (no date, no RLS leak of
-- the private table itself).
update public.seller_profiles set show_age = true where user_id = current_setting('test.s')::uuid;
set local role anon;
do $$
declare a int;
begin
  select age_years into a from public.seller_public_age
   where user_id = current_setting('test.s')::uuid;
  if a is distinct from date_part('year', age(date '1995-06-15'))::int then
    raise exception 'FAIL anon should see the whole-year age, got %', a;
  end if;
  begin
    perform 1 from public.user_private_details;
    raise exception 'FAIL anon read user_private_details';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

rollback;
