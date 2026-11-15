-- Tests for migration 0052. Each failure raises an exception.
begin;

do $$
declare
  uid uuid := gen_random_uuid();
begin
  insert into auth.users (id) values (uid);
  perform set_config('test.uid', uid::text, true);
end $$;

-- RLS enabled on both tables
do $$
begin
  if exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname in ('admin_users','admin_audit_log')
      and not c.relrowsecurity
  ) then raise exception 'RLS not enabled'; end if;
  if exists (select 1 from pg_policies where schemaname='public'
             and tablename in ('admin_users','admin_audit_log')) then
    raise exception 'unexpected client policy';
  end if;
end $$;

-- service role / postgres can insert
insert into public.admin_users (user_id, note)
  values (current_setting('test.uid')::uuid, 'test');

-- anon: select and insert must fail
set local role anon;
do $$
begin
  begin
    perform 1 from public.admin_users;
    raise exception 'anon could select admin_users';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.admin_users (user_id) values (gen_random_uuid());
    raise exception 'anon could insert admin_users';
  exception when insufficient_privilege then null; end;
  begin
    perform 1 from public.admin_audit_log;
    raise exception 'anon could select admin_audit_log';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- authenticated: select and insert must fail
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role', 'authenticated')::text, true);
do $$
begin
  begin
    perform 1 from public.admin_users;
    raise exception 'authenticated could select admin_users';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.admin_users (user_id) values (current_setting('test.uid')::uuid);
    raise exception 'authenticated could insert admin_users';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.admin_audit_log (action) values ('x');
    raise exception 'authenticated could insert admin_audit_log';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

rollback;
