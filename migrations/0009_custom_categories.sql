-- ============================================
-- Migration 0009 — Client custom categories
-- ============================================

alter table public.categories
  add column if not exists is_custom boolean not null default false,
  add column if not exists created_by uuid references public.profiles(id) on delete set null;

-- One canonical name per category (case-insensitive).
create unique index if not exists categories_name_lower_unique
  on public.categories (lower(trim(name)));

create policy "Authenticated users can insert custom categories"
  on public.categories
  for insert
  to authenticated
  with check (
    is_custom = true
    and created_by = auth.uid()
  );
