-- Rollback for 0058. Unschedules the cron job (if pg_cron is present) and drops
-- the function. Deleted notifications are NOT restored. The pg_cron extension is left installed.
begin;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    if exists (select 1 from cron.job where jobname = 'cleanup_old_notifications') then
      perform cron.unschedule('cleanup_old_notifications');
    end if;
  end if;
end $$;

drop function if exists public.cleanup_old_notifications(int);

commit;
