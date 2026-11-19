-- Migration 0058 — Automatic cleanup of old in-app notifications.
-- Deletes public.notifications older than p_days (default 30) by created_at.
-- Scheduled daily at 03:15 UTC via pg_cron when the extension is available;
-- on plain Postgres (no pg_cron) the function is still created and can be
-- called manually or from any external scheduler.
begin;

create or replace function public.cleanup_old_notifications(p_days int default 30)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count bigint;
begin
  if p_days is null or p_days < 1 then
    raise exception 'p_days must be >= 1';
  end if;
  delete from public.notifications
  where created_at < now() - make_interval(days => p_days);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.cleanup_old_notifications(int) from public;
revoke all on function public.cleanup_old_notifications(int) from anon;
revoke all on function public.cleanup_old_notifications(int) from authenticated;

-- Schedule daily via pg_cron, only if available. Idempotent (fixed job name).
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    null;
  elsif exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    begin
      create extension if not exists pg_cron;
    exception when others then
      raise notice 'pg_cron could not be enabled (%); skipping schedule', sqlerrm;
    end;
  else
    raise notice 'pg_cron not available; skipping schedule. Call public.cleanup_old_notifications() from an external scheduler.';
  end if;

  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    begin
      if exists (select 1 from cron.job where jobname = 'cleanup_old_notifications') then
        perform cron.unschedule('cleanup_old_notifications');
      end if;
      perform cron.schedule('cleanup_old_notifications', '15 3 * * *',
                            'select public.cleanup_old_notifications(30)');
    exception when others then
      raise notice 'pg_cron schedule failed (%); function still created', sqlerrm;
    end;
  end if;
end $$;

commit;
