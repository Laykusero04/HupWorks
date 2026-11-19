-- Tests for the DEFERRED migration 0055 (FIX B step B2).
-- NOT RUN YET (no Docker / psql / Supabase CLI when written, T-0128).
-- Runs last (zz_ prefix) because 0055 commits and changes grants for the whole
-- database; it creates its own users and deletes them at the end.
-- Run from the repo root (db_tests/run.sh does): \i uses a repo-relative path.

do $$
declare
  c uuid := gen_random_uuid();
  s uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, raw_user_meta_data)
    values (c, 'b2-client@example.test', '{"role":"client","name":"B2 Client"}'::jsonb);
  insert into auth.users (id, email, raw_user_meta_data)
    values (s, 'b2-seller@example.test', '{"role":"seller","name":"B1 Seller"}'::jsonb);
  perform set_config('test.client', c::text, false);
  perform set_config('test.seller', s::text, false);
  update public.profiles set phone = '0600000000', latitude = 52.1, longitude = 4.5, city = 'Leiden' where id = s;
  update public.profiles set latitude = 52.2, longitude = 4.6 where id = c;
end $$;

\i migrations/deferred_after_r1/0055_fix_b_revoke_public_reads_b2.sql
begin;

set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.client'), 'role', 'authenticated')::text, true);
do $$
declare r jsonb;
begin
  -- public columns of another user still readable
  perform id, name, city, rating, verification_status from public.profiles
   where id = current_setting('test.seller')::uuid;
  perform user_id, job_title, about, skills, show_age from public.seller_profiles
   where user_id = current_setting('test.seller')::uuid;
  -- private columns / select * are refused
  begin perform email from public.profiles; raise exception 'email readable after B2';
  exception when insufficient_privilege then null; end;
  begin perform phone from public.profiles; raise exception 'phone readable after B2';
  exception when insufficient_privilege then null; end;
  begin perform latitude from public.profiles; raise exception 'latitude readable after B2';
  exception when insufficient_privilege then null; end;
  begin perform balance from public.profiles; raise exception 'balance readable after B2';
  exception when insufficient_privilege then null; end;
  begin perform * from public.profiles; raise exception 'select * on profiles allowed after B2';
  exception when insufficient_privilege then null; end;
  begin perform birth_year from public.seller_profiles; raise exception 'birth_year readable after B2';
  exception when insufficient_privilege then null; end;
  begin perform address from public.seller_profiles; raise exception 'address readable after B2';
  exception when insufficient_privilege then null; end;
  -- own data through the views, and RPC / helper functions still work
  perform email, phone, balance from public.my_profile;
  r := public.browse_nearby_sellers('B1', 50, 52.0, 4.4, 10, 0);
  if jsonb_array_length(r) < 1 then raise exception 'browse broke after B2'; end if;
  if public.chat_contact_decision(current_setting('test.seller')::uuid) is null then
    raise exception 'chat_contact_decision broke after B2';
  end if;
  -- own update still works (needs select on id only)
  update public.profiles set bio = 'hello' where id = current_setting('test.client')::uuid;
end $$;
set local role anon;
do $$
begin
  begin perform email from public.profiles; raise exception 'anon reads email after B2';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- cleanup (this file is not transactional)
rollback;
delete from auth.users where id in (current_setting('test.client')::uuid, current_setting('test.seller')::uuid);
