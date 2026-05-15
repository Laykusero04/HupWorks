-- ============================================
-- Migration 0005 — Job post map coordinates
-- ============================================
-- Optional pin from the in-app map picker (center pin + pan).
-- ============================================

alter table public.job_posts
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;
