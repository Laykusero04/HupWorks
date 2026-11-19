-- Migration 0059 — Let users delete their own notifications.
-- Adds a DELETE policy on public.notifications (owner column: user_id).
-- Idempotent: drops the policy first if it already exists.
begin;

drop policy if exists "Users can delete their own notifications" on public.notifications;
create policy "Users can delete their own notifications"
  on public.notifications
  for delete
  to authenticated
  using (auth.uid() = user_id);

commit;
