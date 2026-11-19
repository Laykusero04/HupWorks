-- Test for the DEFERRED migration 0056 (B3): data is carried into
-- seller_private_details (including a seller that had no private row), then the
-- public columns are dropped. NOT RUN YET. Runs after zz_0055 (sorted), commits,
-- so it must stay the last test; it cleans up its users.
-- (0057 refusing to run with placeholders is not tested: \i cannot catch an error.)
do $$
declare s uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, raw_user_meta_data)
    values (s, 'b3-seller@example.test', '{"role":"seller","name":"B3"}'::jsonb);
  perform set_config('test.b3', s::text, false);
  delete from public.seller_private_details where user_id = s;   -- legacy gap
  update public.seller_profiles
     set birth_year = 1991, birth_month = 2, birth_day = 3, address = 'Old Street 9'
   where user_id = s;
end $$;

\i migrations/deferred_after_r1/0056_fix_b_drop_public_pii_columns_b3.sql

do $$
declare p public.seller_private_details;
begin
  select * into p from public.seller_private_details where user_id = current_setting('test.b3')::uuid;
  if p.date_of_birth is distinct from date '1991-02-03' or p.street_address is distinct from 'Old Street 9' then
    raise exception 'B3 did not carry data over: %', row_to_json(p);
  end if;
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'seller_profiles'
               and column_name in ('birth_year','birth_month','birth_day','address')) then
    raise exception 'B3 columns still present';
  end if;
end $$;

delete from auth.users where id = current_setting('test.b3')::uuid;
