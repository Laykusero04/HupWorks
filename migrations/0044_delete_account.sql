-- ============================================
-- Migration 0044 — Instant account deletion
-- Clears order FK blockers, then removes profile + auth user.
-- Self-serve: delete_own_account() (authenticated).
-- Admin: prepare_account_deletion(uid) then auth.admin.deleteUser.
-- ============================================

-- Soft FKs that lack ON DELETE CASCADE / SET NULL
create or replace function public.prepare_account_deletion(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null then
    raise exception 'user_id required';
  end if;

  -- Authenticated callers may only prepare their own account.
  -- Service role (auth.uid() is null) may prepare any account.
  if auth.uid() is not null and auth.uid() is distinct from p_user_id then
    raise exception 'Forbidden';
  end if;

  update public.orders
  set payment_received_by = null
  where payment_received_by = p_user_id;

  update public.orders
  set cancellation_requested_by = null
  where cancellation_requested_by = p_user_id;

  update public.orders
  set cancelled_by = null
  where cancelled_by = p_user_id;

  if to_regclass('public.hour_reports') is not null then
    update public.hour_reports
    set decided_by = null
    where decided_by = p_user_id;
  end if;

  -- Force-cancel open work involving this user, then delete orders
  -- (orders.client_id / seller_id do not cascade from profiles).
  update public.orders
  set
    status = 'cancelled',
    cancelled_at = coalesce(cancelled_at, now()),
    cancellation_reason_code = coalesce(cancellation_reason_code, 'other'),
    cancellation_reason_note = coalesce(
      nullif(trim(cancellation_reason_note), ''),
      'Account deleted'
    ),
    cancellation_requested_at = null,
    cancellation_requested_by = null,
    cancellation_previous_status = null
  where (client_id = p_user_id or seller_id = p_user_id)
    and lower(coalesce(status, '')) <> 'cancelled';

  delete from public.orders
  where client_id = p_user_id or seller_id = p_user_id;
end;
$$;

revoke all on function public.prepare_account_deletion(uuid) from public;
grant execute on function public.prepare_account_deletion(uuid) to authenticated;
grant execute on function public.prepare_account_deletion(uuid) to service_role;

-- Self-serve instant delete (app Settings).
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  perform public.prepare_account_deletion(uid);

  -- Cascades most marketplace rows (seller_profiles, chat, jobs, etc.).
  delete from public.profiles where id = uid;

  -- Remove Auth identity (also cascades verification tables → auth.users).
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
grant execute on function public.delete_own_account() to service_role;

comment on function public.delete_own_account() is
  'Permanently deletes the calling user: cancels/removes their orders, profile data, and auth.users row.';

comment on function public.prepare_account_deletion(uuid) is
  'Clears order FK blockers and deletes orders for a user so profiles/auth can be removed.';
