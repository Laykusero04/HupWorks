-- ============================================
-- Migration 0041 — Saved talent (clients → sellers)
-- Employers bookmark freelancers separately from
-- seller job favourites (`favourites.job_post_id`).
-- ============================================

create table if not exists public.saved_sellers (
  id uuid default gen_random_uuid() primary key,
  client_id uuid not null references public.profiles(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (client_id, seller_id),
  check (client_id <> seller_id)
);

create index if not exists saved_sellers_client_id_idx
  on public.saved_sellers (client_id);
create index if not exists saved_sellers_seller_id_idx
  on public.saved_sellers (seller_id);

alter table public.saved_sellers enable row level security;

drop policy if exists "Users can view their saved sellers" on public.saved_sellers;
create policy "Users can view their saved sellers"
  on public.saved_sellers for select
  using (auth.uid() = client_id);

drop policy if exists "Users can save sellers" on public.saved_sellers;
create policy "Users can save sellers"
  on public.saved_sellers for insert
  with check (auth.uid() = client_id);

drop policy if exists "Users can remove saved sellers" on public.saved_sellers;
create policy "Users can remove saved sellers"
  on public.saved_sellers for delete
  using (auth.uid() = client_id);
