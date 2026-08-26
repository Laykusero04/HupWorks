-- ============================================
-- Migration 0023 — User reports job/contract context
-- Link reports to jobs and contracts when available.
-- ============================================

alter table public.user_reports
  add column if not exists job_post_id uuid references public.job_posts(id) on delete set null,
  add column if not exists order_id uuid references public.orders(id) on delete set null;

create index if not exists user_reports_job_post_id_idx
  on public.user_reports (job_post_id)
  where job_post_id is not null;

create index if not exists user_reports_order_id_idx
  on public.user_reports (order_id)
  where order_id is not null;
