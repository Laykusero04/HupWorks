-- ============================================
-- Migration 0004 — Add free-text location to job_posts
-- ============================================
-- Adds an optional `location` column on job_posts. Free-text so clients can
-- write whatever fits — "Remote", "Manila, PH", "Berlin, Germany", etc.
-- Existing rows get NULL (treated as "unspecified" in the UI).
-- Idempotent — safe to re-run.
-- ============================================

alter table public.job_posts
  add column if not exists location text;
