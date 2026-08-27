-- Completion requires seller delivery, then client approval.
-- Seller cannot mark complete; client cannot complete from pending/active.
-- Safe to re-run.

create or replace function public.enforce_order_status_transitions()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_old text;
  v_new text;
begin
  v_old := lower(coalesce(old.status, ''));
  v_new := lower(coalesce(new.status, ''));

  if v_new is not distinct from v_old then
    return new;
  end if;

  if v_new = 'completed' then
    if v_old <> 'delivered' then
      raise exception 'Order can only be completed after the seller delivers';
    end if;
    if auth.uid() is distinct from old.client_id then
      raise exception 'Only the client can mark this order complete';
    end if;
    if not exists (
      select 1 from public.order_deliveries d where d.order_id = new.id
    ) then
      raise exception 'Order can only be completed after the seller delivers';
    end if;
    if new.completed_at is null then
      new.completed_at := now();
    end if;
  end if;

  if v_new = 'delivered' then
    if auth.uid() is distinct from old.seller_id then
      raise exception 'Only the seller can deliver this order';
    end if;
    if v_old not in ('pending', 'active', 'delivered') then
      raise exception 'This order cannot be delivered from its current status';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_order_status_transitions on public.orders;
create trigger trg_enforce_order_status_transitions
  before update on public.orders
  for each row
  execute function public.enforce_order_status_transitions();
