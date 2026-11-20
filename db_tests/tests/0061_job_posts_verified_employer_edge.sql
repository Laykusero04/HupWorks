-- Edge cases for migration 0061 (job_posts INSERT needs an approved employer
-- verification), QA T-0171. Complements db_tests/tests/0061_job_posts_require_verified_employer.sql.
-- Local throwaway database only. One transaction, rolled back at the end.
begin;

do $$
declare
  u_ok   uuid := gen_random_uuid();  -- personal_id, verified
  u_co   uuid := gen_random_uuid();  -- company track, verified
  u_pend uuid := gen_random_uuid();  -- pending, later approved by admin
  u_self uuid := gen_random_uuid();  -- pending, tries to approve itself
  u_rej  uuid := gen_random_uuid();  -- rejected, tries to approve itself
  u_rev  uuid := gen_random_uuid();  -- verified, later revoked by admin
  u_edit uuid := gen_random_uuid();  -- verified, edits its own documents
  u_none uuid := gen_random_uuid();  -- no verification row
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (u_ok,   'v61e-ok@example.test',   '{"role":"client","name":"Ok"}'),
    (u_co,   'v61e-co@example.test',   '{"role":"client","name":"Co"}'),
    (u_pend, 'v61e-pend@example.test', '{"role":"client","name":"Pend"}'),
    (u_self, 'v61e-self@example.test', '{"role":"client","name":"Self"}'),
    (u_rej,  'v61e-rej@example.test',  '{"role":"client","name":"Rej"}'),
    (u_rev,  'v61e-rev@example.test',  '{"role":"client","name":"Rev"}'),
    (u_edit, 'v61e-edit@example.test', '{"role":"client","name":"Edit"}'),
    (u_none, 'v61e-none@example.test', '{"role":"client","name":"None"}');

  -- Seeded as the migration owner (bypasses the 0053 force-pending trigger).
  insert into public.employer_verifications (user_id, verify_type, id_selfie_path, company_doc_path, status) values
    (u_ok,   'personal_id', 'x/id.jpg',  null,      'verified'),
    (u_co,   'company',     null,        'x/kvk.pdf', 'verified'),
    (u_pend, 'personal_id', 'x/id.jpg',  null,      'pending'),
    (u_self, 'personal_id', 'x/id.jpg',  null,      'pending'),
    (u_rej,  'personal_id', 'x/id.jpg',  null,      'rejected'),
    (u_rev,  'personal_id', 'x/id.jpg',  null,      'verified'),
    (u_edit, 'personal_id', 'x/id.jpg',  null,      'verified');

  perform set_config('v61e.ok', u_ok::text, true);
  perform set_config('v61e.co', u_co::text, true);
  perform set_config('v61e.pend', u_pend::text, true);
  perform set_config('v61e.self', u_self::text, true);
  perform set_config('v61e.rej', u_rej::text, true);
  perform set_config('v61e.rev', u_rev::text, true);
  perform set_config('v61e.edit', u_edit::text, true);
  perform set_config('v61e.none', u_none::text, true);
end $$;

-- Helper: insert a job as "who" for client "owner"; true when allowed.
create or replace function pg_temp.try_post(who uuid, owner uuid) returns boolean
language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', who, 'role', 'authenticated')::text, true);
  begin
    insert into public.job_posts (client_id, title) values (owner, 'edge');
    return true;
  exception when insufficient_privilege then
    return false;
  end;
end $$;
grant execute on function pg_temp.try_post(uuid, uuid) to authenticated;

-- 1. Verified (personal_id) employer can post, and the row lands under their id.
set local role authenticated;
do $$
begin
  if not pg_temp.try_post(current_setting('v61e.ok')::uuid, current_setting('v61e.ok')::uuid) then
    raise exception 'FAIL verified personal_id employer could not post';
  end if;
end $$;
reset role;
do $$
begin
  if (select count(*) from public.job_posts
       where client_id = current_setting('v61e.ok')::uuid and title = 'edge') <> 1 then
    raise exception 'FAIL verified employer post row not stored once';
  end if;
end $$;

-- 2. Verified company track also unlocks posting (any verify_type with status verified).
set local role authenticated;
do $$
begin
  if not pg_temp.try_post(current_setting('v61e.co')::uuid, current_setting('v61e.co')::uuid) then
    raise exception 'FAIL verified company-track employer could not post';
  end if;
end $$;
reset role;

-- 3. Blocked states: no verification, pending, rejected.
set local role authenticated;
do $$
begin
  if pg_temp.try_post(current_setting('v61e.none')::uuid, current_setting('v61e.none')::uuid) then
    raise exception 'FAIL no-verification employer could post';
  end if;
  if pg_temp.try_post(current_setting('v61e.pend')::uuid, current_setting('v61e.pend')::uuid) then
    raise exception 'FAIL pending employer could post';
  end if;
  if pg_temp.try_post(current_setting('v61e.rej')::uuid, current_setting('v61e.rej')::uuid) then
    raise exception 'FAIL rejected employer could post';
  end if;
end $$;
reset role;
do $$
begin
  if (select count(*) from public.job_posts
       where client_id in (current_setting('v61e.none')::uuid,
                           current_setting('v61e.pend')::uuid,
                           current_setting('v61e.rej')::uuid)) <> 0 then
    raise exception 'FAIL a blocked employer left a job row';
  end if;
end $$;

-- 4. Self-approval: an authenticated UPDATE to status 'verified' is forced back to pending.
set local role authenticated;
-- Each user approves itself: claims must match the row, or RLS hides it.
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('v61e.self'), 'role', 'authenticated')::text, true);
do $$
declare n bigint;
begin
  update public.employer_verifications set status = 'verified'
    where user_id = current_setting('v61e.self')::uuid;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL self-approve UPDATE did not match its own row (%)', n; end if;
end $$;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('v61e.rej'), 'role', 'authenticated')::text, true);
do $$
declare n bigint;
begin
  update public.employer_verifications set status = 'verified'
    where user_id = current_setting('v61e.rej')::uuid;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL rejected self-approve UPDATE did not match its own row (%)', n; end if;
end $$;
reset role;
do $$
begin
  if (select status from public.employer_verifications
       where user_id = current_setting('v61e.self')::uuid) <> 'pending' then
    raise exception 'FAIL pending user self-approved via UPDATE';
  end if;
  if (select status from public.employer_verifications
       where user_id = current_setting('v61e.rej')::uuid) <> 'pending' then
    raise exception 'FAIL rejected user self-approved via UPDATE';
  end if;
end $$;
set local role authenticated;
do $$
begin
  if pg_temp.try_post(current_setting('v61e.self')::uuid, current_setting('v61e.self')::uuid) then
    raise exception 'FAIL self-approved (UPDATE) user could post';
  end if;
end $$;
reset role;

-- 5. Admin approval path: service_role sets a pending employer to verified, then posting opens.
set local role authenticated;
do $$
begin
  if pg_temp.try_post(current_setting('v61e.pend')::uuid, current_setting('v61e.pend')::uuid) then
    raise exception 'FAIL pending employer could post before approval';
  end if;
end $$;
reset role;
set local role service_role;
update public.employer_verifications set status = 'verified'
  where user_id = current_setting('v61e.pend')::uuid;
reset role;
set local role authenticated;
do $$
begin
  if not pg_temp.try_post(current_setting('v61e.pend')::uuid, current_setting('v61e.pend')::uuid) then
    raise exception 'FAIL employer approved by service_role could not post';
  end if;
end $$;
reset role;

-- 6. Owner decision 2026-11-20 (ever approved): an admin rejection AFTER an approval does not
-- revoke posting. Revocation = admin clears first_verified_at.
set local role service_role;
update public.employer_verifications set status = 'rejected'
  where user_id = current_setting('v61e.rev')::uuid;
reset role;
set local role authenticated;
do $$
begin
  if not pg_temp.try_post(current_setting('v61e.rev')::uuid, current_setting('v61e.rev')::uuid) then
    raise exception 'FAIL ever-approved employer lost posting after a later rejection';
  end if;
end $$;
reset role;
set local role service_role;
update public.employer_verifications set first_verified_at = null
  where user_id = current_setting('v61e.rev')::uuid;
reset role;
set local role authenticated;
do $$
begin
  if pg_temp.try_post(current_setting('v61e.rev')::uuid, current_setting('v61e.rev')::uuid) then
    raise exception 'FAIL employer could post after admin cleared first_verified_at';
  end if;
end $$;
reset role;

-- 7. Editing own verification documents resets status to pending (0053 trigger, by design).
-- Recorded here so a change to that rule is noticed. Under the ever-approved rule this
-- does NOT block posting (first_verified_at stays set).
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('v61e.edit'), 'role', 'authenticated')::text, true);
do $$
declare n bigint;
begin
  update public.employer_verifications set id_selfie_path = 'x/id-new.jpg'
    where user_id = current_setting('v61e.edit')::uuid;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL edit UPDATE did not match its own row (%)', n; end if;
end $$;
reset role;
do $$
begin
  if (select status from public.employer_verifications
       where user_id = current_setting('v61e.edit')::uuid) <> 'pending' then
    raise exception 'FAIL edited verification kept verified status (0053 rule changed?)';
  end if;
end $$;
set local role authenticated;
do $$
begin
  if not pg_temp.try_post(current_setting('v61e.edit')::uuid, current_setting('v61e.edit')::uuid) then
    raise exception 'FAIL ever-approved employer with edited (pending) verification could not post';
  end if;
end $$;
reset role;

-- 8. Anon can never insert, even for a verified employer.
set local role anon;
do $$
begin
  begin
    insert into public.job_posts (client_id, title)
      values (current_setting('v61e.ok')::uuid, 'anon edge');
    raise exception 'FAIL anon inserted a job';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- 9. service_role (admin tooling) still bypasses the gate for an unverified client.
set local role service_role;
insert into public.job_posts (client_id, title)
  values (current_setting('v61e.none')::uuid, 'admin edge');
reset role;
do $$
begin
  if (select count(*) from public.job_posts
       where client_id = current_setting('v61e.none')::uuid and title = 'admin edge') <> 1 then
    raise exception 'FAIL service_role insert for unverified client did not land';
  end if;
end $$;

rollback;
