-- ============================================
-- Migration 0017 — Skill catalog (trades & labor)
-- Preset skills for freelancers: factory worker, plumber, etc.
-- Linked to existing job categories (not tech roles).
-- Safe to re-run: upserts by skill name.
-- ============================================

create table if not exists public.skill_catalog (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_id uuid references public.categories(id) on delete set null,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create unique index if not exists skill_catalog_name_lower_unique
  on public.skill_catalog (lower(trim(name)));

alter table public.skill_catalog enable row level security;

drop policy if exists "Skill catalog is viewable by everyone" on public.skill_catalog;
create policy "Skill catalog is viewable by everyone"
  on public.skill_catalog for select using (true);

-- Helper: upsert one skill by name + category name
create or replace function public._seed_skill(p_name text, p_category_name text, p_sort int default 0)
returns void
language plpgsql
as $$
declare
  v_category_id uuid;
begin
  select id into v_category_id
  from public.categories
  where lower(trim(name)) = lower(trim(p_category_name))
  limit 1;

  update public.skill_catalog
  set
    category_id = v_category_id,
    sort_order = p_sort,
    is_active = true
  where lower(trim(name)) = lower(trim(p_name));

  if not found then
    insert into public.skill_catalog (name, category_id, sort_order)
    values (p_name, v_category_id, p_sort);
  end if;
end;
$$;

-- Cleaning & Janitorial
select public._seed_skill('Janitor', 'Cleaning & Janitorial', 10);
select public._seed_skill('Office Cleaner', 'Cleaning & Janitorial', 20);
select public._seed_skill('Building Maintenance Worker', 'Cleaning & Janitorial', 30);
select public._seed_skill('Carpet Cleaner', 'Cleaning & Janitorial', 40);
select public._seed_skill('Window Cleaner', 'Cleaning & Janitorial', 50);

-- Factory & Warehouse
select public._seed_skill('Factory Worker', 'Factory & Warehouse', 10);
select public._seed_skill('Production Operator', 'Factory & Warehouse', 20);
select public._seed_skill('Warehouse Associate', 'Factory & Warehouse', 30);
select public._seed_skill('Packer', 'Factory & Warehouse', 40);
select public._seed_skill('Forklift Operator', 'Factory & Warehouse', 50);
select public._seed_skill('Inventory Clerk', 'Factory & Warehouse', 60);
select public._seed_skill('Quality Inspector', 'Factory & Warehouse', 70);

-- Skilled Trades
select public._seed_skill('Plumber', 'Skilled Trades', 10);
select public._seed_skill('Electrician', 'Skilled Trades', 20);
select public._seed_skill('Carpenter', 'Skilled Trades', 30);
select public._seed_skill('Mason', 'Skilled Trades', 40);
select public._seed_skill('Welder', 'Skilled Trades', 50);
select public._seed_skill('Painter', 'Skilled Trades', 60);
select public._seed_skill('HVAC Technician', 'Skilled Trades', 70);
select public._seed_skill('Auto Mechanic', 'Skilled Trades', 80);
select public._seed_skill('Roofer', 'Skilled Trades', 90);
select public._seed_skill('Tile Setter', 'Skilled Trades', 100);

-- Beauty & Salon
select public._seed_skill('Hairdresser', 'Beauty & Salon', 10);
select public._seed_skill('Barber', 'Beauty & Salon', 20);
select public._seed_skill('Nail Technician', 'Beauty & Salon', 30);
select public._seed_skill('Makeup Artist', 'Beauty & Salon', 40);
select public._seed_skill('Massage Therapist', 'Beauty & Salon', 50);

-- Food Service
select public._seed_skill('Waiter / Server', 'Food Service', 10);
select public._seed_skill('Cook', 'Food Service', 20);
select public._seed_skill('Line Cook', 'Food Service', 30);
select public._seed_skill('Baker', 'Food Service', 40);
select public._seed_skill('Dishwasher', 'Food Service', 50);
select public._seed_skill('Barista', 'Food Service', 60);
select public._seed_skill('Kitchen Helper', 'Food Service', 70);

-- Retail & Sales
select public._seed_skill('Cashier', 'Retail & Sales', 10);
select public._seed_skill('Sales Associate', 'Retail & Sales', 20);
select public._seed_skill('Store Stocker', 'Retail & Sales', 30);
select public._seed_skill('Merchandiser', 'Retail & Sales', 40);

-- Delivery & Driving
select public._seed_skill('Delivery Driver', 'Delivery & Driving', 10);
select public._seed_skill('Courier', 'Delivery & Driving', 20);
select public._seed_skill('Truck Driver', 'Delivery & Driving', 30);
select public._seed_skill('Van Driver', 'Delivery & Driving', 40);

-- General Labor
select public._seed_skill('Construction Helper', 'General Labor', 10);
select public._seed_skill('Mover', 'General Labor', 20);
select public._seed_skill('Handyman', 'General Labor', 30);
select public._seed_skill('General Laborer', 'General Labor', 40);
select public._seed_skill('Landscaper', 'General Labor', 50);
select public._seed_skill('Security Guard', 'General Labor', 60);
select public._seed_skill('Event Setup Crew', 'General Labor', 70);

drop function if exists public._seed_skill(text, text, int);
