-- ============================================
-- Migration 0005 — Add `workers_needed` to job_posts
-- ============================================
-- How many freelancers the client wants to hire for this job.
-- Defaults to 1 (single-hire) — covers most existing rows.
-- Idempotent — safe to re-run.
-- ============================================

alter table public.job_posts
  add column if not exists workers_needed int not null default 1
    check (workers_needed >= 1);
