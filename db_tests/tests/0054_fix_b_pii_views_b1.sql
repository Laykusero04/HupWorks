-- Tests for migration 0054 (FIX B step B1). B2 is tested in zz_0055_fix_b_b2.sql.
-- NOT RUN YET (no Docker / psql / Supabase CLI when written, T-0128).
begin;

do $$
declare
  c uuid := gen_random_uuid();
  s uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, raw_user_meta_data)
    values (c, 'b1-client@example.test', '{"role":"client","name":"B1 Client"}'::jsonb);
  insert into auth.users (id, email, raw_user_meta_data)
    values (s, 'b1-seller@example.test', '{"role":"seller","name":"B1 Seller"}'::jsonb);
  perform set_config('test.client', c::text, true);
  perform set_config('test.seller', s::text, true);

  update public.profiles
     set phone = '0600000000', latitude = 52.1, longitude = 4.5, city = 'Leiden'
   where id = s;
  update public.seller_profiles set job_title = 'Barista', show_age = false,
         birth_year = 1990, birth_month = 5, birth_day = 17, address = 'Street 1' where user_id = s;
  update public.seller_private_details set date_of_birth = date '1990-05-17',
         street_address = 'Street 1' where user_id = s;
  update public.profiles set latitude = 52.2, longitude = 4.6 where id = c;
end $$;

-- show_age defaults to false
do $$
begin
  if (select show_age from public.seller_profiles where user_id = current_setting('test.seller')::uuid) then
    raise exception 'show_age must default to false';
  end if;
end $$;

-- seller_public_age: hidden until consent, then whole years
do $$
declare a int;
begin
  select age_years into a from public.seller_public_age
   where user_id = current_setting('test.seller')::uuid;
  if a is not null then raise exception 'age exposed without consent'; end if;

  update public.seller_profiles set show_age = true
   where user_id = current_setting('test.seller')::uuid;
  select age_years into a from public.seller_public_age
   where user_id = current_setting('test.seller')::uuid;
  if a is distinct from date_part('year', age(date '1990-05-17'))::int then
    raise exception 'wrong age_years: %', a;
  end if;
  update public.seller_profiles set show_age = false
   where user_id = current_setting('test.seller')::uuid;
end $$;

-- ---- as the seller: own views return own full row only ----
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.seller'), 'role', 'authenticated')::text, true);
do $$
begin
  if (select count(*) from public.my_profile) <> 1 then raise exception 'my_profile must return exactly my row'; end if;
  if (select phone from public.my_profile) <> '0600000000' then raise exception 'my_profile lacks own phone'; end if;
  if (select count(*) from public.my_seller_profile) <> 1 then raise exception 'my_seller_profile must return my row'; end if;
  begin
    update public.my_profile set name = 'x';
    raise exception 'my_profile must not be updatable';
  exception when insufficient_privilege then null; end;
end $$;

-- ---- as the client: sees only own row in my_profile; browse has no coordinates ----
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.client'), 'role', 'authenticated')::text, true);
do $$
declare r jsonb;
begin
  if (select count(*) from public.my_profile) <> 1
     or (select id from public.my_profile) <> current_setting('test.client')::uuid then
    raise exception 'my_profile leaked another row';
  end if;
  if (select count(*) from public.my_seller_profile) <> 0 then
    raise exception 'my_seller_profile leaked another row';
  end if;
  r := public.browse_nearby_sellers('B1', 50, 52.0, 4.4, 10, 0);
  if jsonb_array_length(r) < 1 then raise exception 'browse_nearby_sellers returned nothing'; end if;
  if r->0 ? 'latitude' or r->0 ? 'longitude' then
    raise exception 'browse_nearby_sellers still returns coordinates';
  end if;
  if (r->0->>'distance_km') is null then raise exception 'distance_km missing'; end if;
end $$;
reset role;

-- ---- anon: my_* views not readable, public age readable, browse not callable ----
set local role anon;
do $$
begin
  begin perform 1 from public.my_profile; raise exception 'anon read my_profile';
  exception when insufficient_privilege then null; end;
  begin perform public.browse_nearby_sellers(); raise exception 'anon called browse_nearby_sellers';
  exception when insufficient_privilege then null; end;
  perform 1 from public.seller_public_age;
end $$;
reset role;

-- ---- min build gate ----
do $$
declare j jsonb;
begin
  j := public.get_min_app_build('ios');
  if (j->>'min_build')::int <> 0 then raise exception 'min build should start at 0'; end if;
end $$;
set local role anon;
do $$
begin
  perform public.get_min_app_build('android');
  begin perform 1 from public.app_config; raise exception 'anon read app_config';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

rollback;
