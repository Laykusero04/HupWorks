-- ============================================
-- Migration 0001 — Phase 1 of FLOW_MIGRATION.md
-- ============================================
-- Adds:
--   * job_posts.job_type        ('gig' | 'full_time' | 'part_time'), default 'gig'
--   * orders.job_offer_id       nullable FK -> job_offers(id)
--   * reviews.job_offer_id      nullable FK -> job_offers(id)
--
-- Additive only — no UI change, no data loss, idempotent.
-- Run in: Supabase Dashboard > SQL Editor
-- ============================================

-- 1. Add job_type to job_posts.
--    The NOT NULL DEFAULT clause backfills existing rows with 'gig'
--    in a single statement — no separate UPDATE needed.
alter table public.job_posts
  add column if not exists job_type text not null default 'gig'
    check (job_type in ('gig', 'full_time', 'part_time'));

-- 2. Link orders -> job_offers.
--    Nullable so existing service-based orders keep working.
--    ON DELETE SET NULL keeps the order row if the offer is deleted.
alter table public.orders
  add column if not exists job_offer_id uuid
    references public.job_offers(id) on delete set null;

create index if not exists orders_job_offer_id_idx
  on public.orders(job_offer_id);

-- 3. Link reviews -> job_offers (parallel to orders).
alter table public.reviews
  add column if not exists job_offer_id uuid
    references public.job_offers(id) on delete set null;

create index if not exists reviews_job_offer_id_idx
  on public.reviews(job_offer_id);
