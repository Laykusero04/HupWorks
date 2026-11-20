-- Tests for migration 0061: job_posts INSERT needs an employer who was approved at
-- least once (employer_verifications.first_verified_at), owner decision 2026-11-20.
begin;

do $$
declare
  u_none uuid := gen_random_uuid();   -- no verification row
  u_pend uuid := gen_random_uuid();   -- pending
  u_rej  uuid := gen_random_uuid();   -- rejected
  u_ok   uuid := gen_random_uuid();   -- verified
  u_old  uuid := gen_random_uuid();   -- has an old job, not verified
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (u_none, 'v61-none@example.test', '{"role":"client","name":"None"}'),
    (u_pend, 'v61-pend@example.test', '{"role":"client","name":"Pend"}'),
    (u_rej,  'v61-rej@example.test',  '{"role":"client","name":"Rej"}'),
    (u_ok,   'v61-ok@example.test',   '{"role":"client","name":"Ok"}'),
    (u_old,  'v61-old@example.test',  '{"role":"client","name":"Old"}');

  -- Seeded as the migration owner (bypasses the 0053 force-pending trigger).
  insert into public.employer_verifications (user_id, verify_type, id_selfie_path, status) values
    (u_pend, 'personal_id', 'x/id.jpg', 'pending'),
    (u_rej,  'personal_id', 'x/id.jpg', 'rejected'),
    (u_ok,   'personal_id', 'x/id.jpg', 'verified');

  -- A job that existed before the gate (owner insert, like service role).
  insert into public.job_posts (client_id, title) values (u_old, 'legacy open job');

  perform set_config('test.none', u_none::text, true);
  perform set_config('test.pend', u_pend::text, true);
  perform set_config('test.rej',  u_rej::text, true);
  perform set_config('test.ok',   u_ok::text, true);
  perform set_config('test.old',  u_old::text, true);
end $$;

-- Helper: try an insert as a given user; true when allowed.
create or replace function pg_temp.try_insert(who uuid, owner uuid) returns boolean
language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', who, 'role', 'authenticated')::text, true);
  begin
    insert into public.job_posts (client_id, title) values (owner, 'T');
    return true;
  exception when insufficient_privilege then
    return false;
  end;
end $$;
grant execute on function pg_temp.try_insert(uuid, uuid) to authenticated;

set local role authenticated;

do $$
begin
  if pg_temp.try_insert(current_setting('test.none')::uuid, current_setting('test.none')::uuid) then
    raise exception 'FAIL: employer with no verification could post';
  end if;
  if pg_temp.try_insert(current_setting('test.pend')::uuid, current_setting('test.pend')::uuid) then
    raise exception 'FAIL: pending employer could post';
  end if;
  if pg_temp.try_insert(current_setting('test.rej')::uuid, current_setting('test.rej')::uuid) then
    raise exception 'FAIL: rejected employer could post';
  end if;
  if not pg_temp.try_insert(current_setting('test.ok')::uuid, current_setting('test.ok')::uuid) then
    raise exception 'FAIL: verified employer could not post';
  end if;
  -- a verified user cannot post on behalf of someone else
  if pg_temp.try_insert(current_setting('test.ok')::uuid, current_setting('test.none')::uuid) then
    raise exception 'FAIL: verified user posted as another client';
  end if;
  -- someone else's verification does not help
  if pg_temp.try_insert(current_setting('test.none')::uuid, current_setting('test.ok')::uuid) then
    raise exception 'FAIL: unverified user posted as the verified client';
  end if;
end $$;

-- ever-approved semantics ------------------------------------------------
-- The seeded 'verified' row was stamped by the trigger (checked as owner).
reset role;
do $$
begin
  if (select first_verified_at from public.employer_verifications
      where user_id = current_setting('test.ok')::uuid) is null then
    raise exception 'FAIL: approval did not stamp first_verified_at';
  end if;
  if exists (select 1 from public.employer_verifications
      where user_id in (current_setting('test.pend')::uuid, current_setting('test.rej')::uuid)
        and first_verified_at is not null) then
    raise exception 'FAIL: pending/rejected row got stamped';
  end if;
end $$;

set local role authenticated;

-- Approved employer edits their documents: record goes back to pending
-- (0053) but posting is still allowed.
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.ok'), 'role', 'authenticated')::text, true);
update public.employer_verifications
  set id_selfie_path = 'x/new.jpg', status = 'pending'
  where user_id = current_setting('test.ok')::uuid;
do $$
begin
  if (select status from public.employer_verifications
      where user_id = current_setting('test.ok')::uuid) <> 'pending' then
    raise exception 'FAIL: edited record is not pending';
  end if;
  if not pg_temp.try_insert(current_setting('test.ok')::uuid, current_setting('test.ok')::uuid) then
    raise exception 'FAIL: approved employer lost posting rights after editing docs';
  end if;
end $$;

-- API users cannot clear or forge the marker.
update public.employer_verifications set first_verified_at = null
  where user_id = current_setting('test.ok')::uuid;
update public.employer_verifications set first_verified_at = now()
  where user_id = current_setting('test.pend')::uuid;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.pend'), 'role', 'authenticated')::text, true);
update public.employer_verifications set first_verified_at = now()
  where user_id = current_setting('test.pend')::uuid;
do $$
begin
  if pg_temp.try_insert(current_setting('test.pend')::uuid, current_setting('test.pend')::uuid) then
    raise exception 'FAIL: API user forged first_verified_at';
  end if;
end $$;
reset role;
do $$
begin
  if (select first_verified_at from public.employer_verifications
      where user_id = current_setting('test.ok')::uuid) is null then
    raise exception 'FAIL: API user cleared first_verified_at';
  end if;
end $$;

-- Admin (service_role) revokes by clearing it: blocked again.
set local role service_role;
update public.employer_verifications set first_verified_at = null
  where user_id = current_setting('test.ok')::uuid;
reset role;
set local role authenticated;
do $$
begin
  if pg_temp.try_insert(current_setting('test.ok')::uuid, current_setting('test.ok')::uuid) then
    raise exception 'FAIL: employer still posts after admin cleared first_verified_at';
  end if;
end $$;
reset role;

-- Admin approves again (status -> verified): re-stamped, posting works.
set local role service_role;
update public.employer_verifications set status = 'verified'
  where user_id = current_setting('test.ok')::uuid;
reset role;
set local role authenticated;
do $$
begin
  if not pg_temp.try_insert(current_setting('test.ok')::uuid, current_setting('test.ok')::uuid) then
    raise exception 'FAIL: re-approved employer cannot post';
  end if;
end $$;
-- stay as authenticated for the rest of the file (as before)

-- A user cannot self-approve: the 0053 trigger forces their write to 'pending'.
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.none'), 'role', 'authenticated')::text, true);
insert into public.employer_verifications (user_id, verify_type, id_selfie_path, status)
  values (current_setting('test.none')::uuid, 'personal_id', 'x/id.jpg', 'verified');
do $$
begin
  if pg_temp.try_insert(current_setting('test.none')::uuid, current_setting('test.none')::uuid) then
    raise exception 'FAIL: self-submitted "verified" unlocked posting';
  end if;
end $$;

-- Existing rows: an unverified owner can still see, update and delete their old job.
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.old'), 'role', 'authenticated')::text, true);
do $$
declare n bigint;
begin
  select count(*) into n from public.job_posts where title = 'legacy open job';
  if n <> 1 then raise exception 'FAIL: old job not visible (%)', n; end if;
  update public.job_posts set title = 'legacy edited'
    where client_id = current_setting('test.old')::uuid;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL: owner could not update existing job (%)', n; end if;
  delete from public.job_posts where client_id = current_setting('test.old')::uuid;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL: owner could not delete existing job (%)', n; end if;
end $$;

-- Other people's rows stay protected from update.
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.none'), 'role', 'authenticated')::text, true);
do $$
declare n bigint;
begin
  update public.job_posts set title = 'hijack'
    where client_id = current_setting('test.ok')::uuid;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: updated someone else''s job (%)', n; end if;
end $$;
reset role;

-- service_role (admin tooling) is unaffected, even for an unverified client.
set local role service_role;
do $$
begin
  insert into public.job_posts (client_id, title)
    values (current_setting('test.rej')::uuid, 'admin-created');
end $$;
reset role;

-- anon cannot insert at all.
set local role anon;
do $$
begin
  begin
    insert into public.job_posts (client_id, title)
      values (current_setting('test.ok')::uuid, 'anon');
    raise exception 'FAIL: anon inserted a job';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

rollback;
