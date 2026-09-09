-- ============================================
-- Migration 0042 — Withdraw pending job offer
-- ============================================

-- Allow "withdrawn" on job_offers (FLOW_MIGRATION planned status).
alter table public.job_offers drop constraint if exists job_offers_status_check;

alter table public.job_offers
  add constraint job_offers_status_check
  check (status in ('pending', 'accepted', 'rejected', 'withdrawn'));

-- Seller withdraws their own pending application.
create or replace function public.withdraw_job_offer(p_offer_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_offer public.job_offers%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_offer
  from public.job_offers
  where id = p_offer_id
  for update;

  if not found then
    raise exception 'Offer not found';
  end if;

  if v_offer.seller_id is distinct from auth.uid() then
    raise exception 'Only the applicant can withdraw this offer';
  end if;

  if lower(coalesce(v_offer.status, '')) <> 'pending' then
    raise exception 'Only pending offers can be withdrawn';
  end if;

  update public.job_offers
  set status = 'withdrawn'
  where id = p_offer_id;
end;
$$;

grant execute on function public.withdraw_job_offer(uuid) to authenticated;
