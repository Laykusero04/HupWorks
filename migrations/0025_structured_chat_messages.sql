-- ============================================
-- Migration 0025 — Structured chat message types
-- Links bid cards to job_offers rows for inline hire actions
-- ============================================

alter table public.messages
  add column if not exists message_type text not null default 'text'
    check (message_type in ('text', 'job_offer', 'counter_offer')),
  add column if not exists job_offer_id uuid references public.job_offers(id) on delete set null;

create index if not exists messages_job_offer_id_idx on public.messages(job_offer_id);
