-- Tests for migration 0059: users can delete only their own notifications.
begin;

do $$
declare a uuid := gen_random_uuid(); b uuid := gen_random_uuid();
begin
  insert into auth.users (id, email) values
    (a, 'notif-del-a@example.test'), (b, 'notif-del-b@example.test');
  insert into public.notifications (user_id, title) values
    (a, 'a-1'), (a, 'a-2'), (b, 'b-1');
  perform set_config('test.a', a::text, true);
  perform set_config('test.b', b::text, true);
end $$;

-- anon cannot delete anything (no policy and/or no grant)
set local role anon;
do $$
declare n bigint;
begin
  begin
    delete from public.notifications;
    get diagnostics n = row_count;
    if n <> 0 then raise exception 'FAIL anon deleted % rows', n; end if;
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- user A: deletes own, cannot delete B's
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.a'), 'role', 'authenticated')::text, true);
do $$
declare n bigint;
begin
  delete from public.notifications where user_id = current_setting('test.b')::uuid;
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL user A deleted % of B rows', n; end if;

  delete from public.notifications where title = 'a-1';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL user A could not delete own row (%)', n; end if;

  -- unfiltered delete only ever touches own rows
  delete from public.notifications;
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL delete-all by A removed % rows (expected 1)', n; end if;
end $$;
reset role;

do $$
begin
  if (select count(*) from public.notifications
       where user_id = current_setting('test.b')::uuid) <> 1 then
    raise exception 'FAIL B notification missing after A deletes';
  end if;
  if exists (select 1 from public.notifications
              where user_id = current_setting('test.a')::uuid) then
    raise exception 'FAIL A rows still present';
  end if;
  if not exists (select 1 from pg_policies where schemaname='public'
      and tablename='notifications' and cmd='DELETE'
      and policyname='Users can delete their own notifications') then
    raise exception 'FAIL policy missing';
  end if;
end $$;

rollback;
