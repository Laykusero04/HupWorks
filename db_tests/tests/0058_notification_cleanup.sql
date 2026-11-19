-- Tests for migration 0058. Each failure raises an exception.
begin;

do $$
declare
  uid uuid := gen_random_uuid();
begin
  -- signup trigger creates the profile; it needs an email to derive a name
  insert into auth.users (id, email) values (uid, 'notif-cleanup-test@example.test');
  perform set_config('test.uid', uid::text, true);
end $$;

insert into public.notifications (user_id, title, created_at) values
  (current_setting('test.uid')::uuid, 'old-31d',  now() - interval '31 days'),
  (current_setting('test.uid')::uuid, 'old-90d',  now() - interval '90 days'),
  (current_setting('test.uid')::uuid, 'new-29d',  now() - interval '29 days'),
  (current_setting('test.uid')::uuid, 'new-now',  now());

do $$
declare n bigint;
begin
  n := public.cleanup_old_notifications();
  if n <> 2 then raise exception 'expected 2 deleted, got %', n; end if;
  if exists (select 1 from public.notifications where title in ('old-31d','old-90d')) then
    raise exception 'old notifications not deleted';
  end if;
  if (select count(*) from public.notifications where title in ('new-29d','new-now')) <> 2 then
    raise exception 'recent notifications were deleted';
  end if;
  -- custom window: only new-29d is older than 7 days
  n := public.cleanup_old_notifications(7);
  if n <> 1 then raise exception 'p_days=7 expected 1 deleted, got %', n; end if;
  begin
    perform public.cleanup_old_notifications(0);
    raise exception 'FAIL p_days=0 should be rejected';
  exception when raise_exception then
    if sqlerrm like 'FAIL%' then raise; end if;
  end;
end $$;

-- hardened: SECURITY DEFINER, fixed search_path, not callable by API roles
do $$
declare cfg text[];
begin
  select proconfig into cfg from pg_proc
   where oid = 'public.cleanup_old_notifications(int)'::regprocedure and prosecdef;
  if cfg is null or not (cfg::text like '%search_path=public, pg_temp%') then
    raise exception 'not security definer with fixed search_path: %', cfg;
  end if;
end $$;

set local role anon;
do $$ begin
  begin perform public.cleanup_old_notifications();
    raise exception 'anon could execute';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
set local role authenticated;
do $$ begin
  begin perform public.cleanup_old_notifications();
    raise exception 'authenticated could execute';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

rollback;
