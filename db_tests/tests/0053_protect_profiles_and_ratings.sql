-- Tests for migration 0053 (HOTFIX A). A failure raises an exception.
-- NOT RUN YET (no Docker / psql / Supabase CLI when written, T-0121).
begin;

-- Two users created like a real signup: the auth.users trigger (handle_new_user)
-- creates their profiles as postgres, which must still work.
do $$
declare
  c uuid := gen_random_uuid();
  s uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, raw_user_meta_data)
    values (c, 'a53-client@example.test', '{"role":"client","name":"QA Client"}'::jsonb);
  insert into auth.users (id, email, raw_user_meta_data)
    values (s, 'a53-seller@example.test', '{"role":"seller","name":"QA Seller"}'::jsonb);
  perform set_config('test.client', c::text, true);
  perform set_config('test.seller', s::text, true);

  if (select role from public.profiles where id = c) <> 'client' then
    raise exception 'signup trigger: client profile missing or wrong role';
  end if;
  if (select role from public.profiles where id = s) <> 'seller' then
    raise exception 'signup trigger: seller profile missing or wrong role';
  end if;
end $$;

-- One completed order so reviews can be inserted.
do $$
declare o uuid;
begin
  insert into public.orders (client_id, seller_id, price, status)
  values (current_setting('test.client')::uuid, current_setting('test.seller')::uuid, 10, 'completed')
  returning id into o;
  perform set_config('test.order', o::text, true);
end $$;

-- ---- act as the client through the API ----
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.client'), 'role', 'authenticated')::text, true);

-- T1 own profile update still works
update public.profiles set name = 'QA Client 2', phone = '0612345678', city = 'Leiden'
where id = current_setting('test.client')::uuid;
do $$
begin
  if (select city from public.profiles where id = current_setting('test.client')::uuid) is distinct from 'Leiden' then
    raise exception 'T1 own profile update failed';
  end if;
end $$;

-- T2 protected columns are ignored (no error, no change)
update public.profiles
set rating = 5.0, balance = 9999, role = 'seller',
    verification_status = 'verified', profile_photo_status = 'verified'
where id = current_setting('test.client')::uuid;
do $$
declare p public.profiles;
begin
  select * into p from public.profiles where id = current_setting('test.client')::uuid;
  if p.rating <> 0 or p.balance <> 0 or p.role <> 'client'
     or p.verification_status is distinct from 'unverified'
     or p.profile_photo_status is distinct from 'unverified' then
    raise exception 'T2 protected columns changed: %', row_to_json(p);
  end if;
end $$;

-- T3 resubmission to pending is still allowed
update public.profiles set verification_status = 'pending', profile_photo_status = 'pending'
where id = current_setting('test.client')::uuid;
do $$
declare p public.profiles;
begin
  select * into p from public.profiles where id = current_setting('test.client')::uuid;
  if p.verification_status <> 'pending' or p.profile_photo_status <> 'pending' then
    raise exception 'T3 pending resubmission blocked';
  end if;
end $$;

-- T4 cannot self-approve through employer_verifications
insert into public.employer_verifications (user_id, verify_type, id_selfie_path, status, reviewed_at)
values (current_setting('test.client')::uuid, 'personal_id', 'x/selfie.jpg', 'verified', now())
on conflict (user_id) do update set status = 'verified', reviewed_at = now();
do $$
begin
  if (select status from public.employer_verifications
      where user_id = current_setting('test.client')::uuid) <> 'pending' then
    raise exception 'T4 employer self-approval not blocked';
  end if;
  if (select verification_status from public.profiles
      where id = current_setting('test.client')::uuid) = 'verified' then
    raise exception 'T4 profile became verified';
  end if;
end $$;

-- T5 cannot update someone else's profile (0 rows, no error)
update public.profiles set name = 'hacked' where id = current_setting('test.seller')::uuid;
do $$
begin
  if (select name from public.profiles where id = current_setting('test.seller')::uuid) = 'hacked' then
    raise exception 'T5 updated another user''s profile';
  end if;
end $$;

-- T5b cannot move own row to another id
do $$
begin
  begin
    update public.profiles set id = current_setting('test.seller')::uuid
    where id = current_setting('test.client')::uuid;
    raise exception 'T5b id move was allowed';
  exception when others then
    if sqlerrm = 'T5b id move was allowed' then raise; end if;
  end;
end $$;

-- T5c the client-side rating write the old app does is a silent no-op
update public.profiles set rating = 4.9 where id = current_setting('test.client')::uuid;
do $$
begin
  if (select rating from public.profiles where id = current_setting('test.client')::uuid) <> 0 then
    raise exception 'T5c client rating write changed the rating';
  end if;
end $$;

-- T5d changing the photo sends it back to review even if status is left alone / set to verified
reset role;
update public.profiles set profile_photo_status = 'verified', profile_photo_reviewed_at = now()
 where id = current_setting('test.client')::uuid;            -- as postgres: simulate an approved photo
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.client'), 'role', 'authenticated')::text, true);
update public.profiles set profile_image_url = 'https://example.test/other.jpg'
 where id = current_setting('test.client')::uuid;
do $$
declare p public.profiles;
begin
  select * into p from public.profiles where id = current_setting('test.client')::uuid;
  if p.profile_photo_status <> 'pending' or p.profile_photo_reviewed_at is not null then
    raise exception 'T5d photo change did not reset review: %', row_to_json(p);
  end if;
end $$;
update public.profiles set profile_photo_status = 'pending' where id = current_setting('test.client')::uuid;
reset role;
update public.profiles set profile_photo_status = 'verified' where id = current_setting('test.client')::uuid;
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.client'), 'role', 'authenticated')::text, true);
update public.profiles set profile_image_url = 'https://example.test/third.jpg',
       profile_photo_status = 'verified'
 where id = current_setting('test.client')::uuid;
do $$
begin
  if (select profile_photo_status from public.profiles where id = current_setting('test.client')::uuid) <> 'pending' then
    raise exception 'T5d2 photo change + self-verify not blocked';
  end if;
end $$;
-- unrelated update keeps an approved photo approved
reset role;
update public.profiles set profile_photo_status = 'verified' where id = current_setting('test.client')::uuid;
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.client'), 'role', 'authenticated')::text, true);
update public.profiles set bio = 'same photo' where id = current_setting('test.client')::uuid;
do $$
begin
  if (select profile_photo_status from public.profiles where id = current_setting('test.client')::uuid) <> 'verified' then
    raise exception 'T5d3 unrelated update reset the photo status';
  end if;
end $$;

-- T5e API roles cannot execute the definer / trigger helpers directly
do $$
begin
  begin perform public.recalc_profile_rating(current_setting('test.client')::uuid);
    raise exception 'T5e authenticated executed recalc_profile_rating';
  exception when insufficient_privilege then null; end;
end $$;

reset role;

-- T6 rating follows reviews (postgres inserts the review; trigger recalculates)
insert into public.reviews (order_id, reviewer_id, reviewed_id, rating)
values (current_setting('test.order')::uuid, current_setting('test.client')::uuid,
        current_setting('test.seller')::uuid, 4);
do $$
begin
  if (select rating from public.profiles where id = current_setting('test.seller')::uuid) <> 4.0 then
    raise exception 'T6 rating not recalculated from reviews';
  end if;
end $$;

-- T7 admin / service path still works
update public.employer_verifications set status = 'verified', reviewed_at = now()
where user_id = current_setting('test.client')::uuid;
do $$
begin
  if (select verification_status from public.profiles
      where id = current_setting('test.client')::uuid) <> 'verified' then
    raise exception 'T7 admin approval did not sync to profiles';
  end if;
end $$;

-- T8 client-side signup insert (ensureProfileExists) gets safe defaults
do $$
declare n uuid := gen_random_uuid();
begin
  insert into auth.users (id, email) values (n, 'a53-new@example.test');
  delete from public.profiles where id = n;       -- simulate "trigger did not run"
  perform set_config('test.new', n::text, true);
end $$;
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.new'), 'role', 'authenticated')::text, true);
insert into public.profiles (id, role, name, email, rating, balance, verification_status)
values (current_setting('test.new')::uuid, 'client', 'New', 'new@example.test', 5, 100, 'verified');
reset role;
do $$
declare p public.profiles;
begin
  select * into p from public.profiles where id = current_setting('test.new')::uuid;
  if p.rating <> 0 or p.balance <> 0 or p.verification_status <> 'unverified' then
    raise exception 'T8 signup insert not clamped: %', row_to_json(p);
  end if;
end $$;

-- T9 the signup trigger itself keeps working with the protection in place
do $$
declare n uuid := gen_random_uuid();
begin
  insert into auth.users (id, email, raw_user_meta_data)
    values (n, 'a53-t9@example.test', '{"role":"seller","name":"T9"}'::jsonb);
  if not exists (select 1 from public.profiles where id = n and role = 'seller')
     or not exists (select 1 from public.seller_profiles where user_id = n)
     or not exists (select 1 from public.seller_private_details where user_id = n) then
    raise exception 'T9 handle_new_user did not create seller rows';
  end if;
end $$;

rollback;
