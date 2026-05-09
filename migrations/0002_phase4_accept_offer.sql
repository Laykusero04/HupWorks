-- ============================================
-- Migration 0002 — Phase 4 of FLOW_MIGRATION.md
-- ============================================
-- 1. Relax orders.service_id NOT NULL so contracts created from job_offers
--    (which have no associated service) are valid.
-- 2. Add accept_job_offer(uuid) RPC that atomically:
--      - marks the offer accepted
--      - rejects sibling pending offers on the same job post
--      - closes the parent job post
--      - inserts a contract (orders row) linked via job_offer_id
--
-- All four side-effects must succeed together, so they live inside a single
-- SECURITY DEFINER plpgsql function with its own auth check.
-- Run in: Supabase Dashboard > SQL Editor
-- ============================================

-- 1. Make service_id optional. Existing rows keep their values; new rows
--    created from job offers can leave it null.
alter table public.orders
  alter column service_id drop not null;

-- 2. The accept RPC.
create or replace function public.accept_job_offer(p_offer_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_offer record;
  v_order_id uuid;
  v_deadline timestamptz;
begin
  select jo.id, jo.job_post_id, jo.seller_id, jo.price, jo.delivery_time,
         jp.client_id as job_client_id
    into v_offer
    from public.job_offers jo
    join public.job_posts  jp on jp.id = jo.job_post_id
    where jo.id = p_offer_id;

  if not found then
    raise exception 'Offer not found';
  end if;

  -- Only the client who posted the job may accept.
  if v_offer.job_client_id <> auth.uid() then
    raise exception 'Not authorized';
  end if;

  v_deadline := now() + (v_offer.delivery_time::text || ' days')::interval;

  -- (a) accept this offer
  update public.job_offers set status = 'accepted' where id = p_offer_id;

  -- (b) auto-reject sibling pending offers on the same job
  update public.job_offers
     set status = 'rejected'
   where job_post_id = v_offer.job_post_id
     and id <> p_offer_id
     and status = 'pending';

  -- (c) close the parent job post
  update public.job_posts set status = 'closed' where id = v_offer.job_post_id;

  -- (d) create the contract
  insert into public.orders
    (job_offer_id, client_id, seller_id, price, status, delivery_deadline)
  values
    (p_offer_id, v_offer.job_client_id, v_offer.seller_id, v_offer.price,
     'pending', v_deadline)
  returning id into v_order_id;

  return v_order_id;
end;
$$;

grant execute on function public.accept_job_offer(uuid) to authenticated;
