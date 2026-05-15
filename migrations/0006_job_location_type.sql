-- ============================================
-- Migration 0006 — Job post location type
-- ============================================
alter table public.job_posts
  add column if not exists location_type text
    check (location_type in ('On-site', 'Remote'));
