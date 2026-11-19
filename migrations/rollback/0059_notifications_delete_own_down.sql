-- Rollback for 0059. Removes the user DELETE policy. Already deleted rows are NOT restored.
begin;
drop policy if exists "Users can delete their own notifications" on public.notifications;
commit;
