-- ============================================
-- Migration 0008 — Categories for local / onsite jobs
-- ============================================
-- Replaces freelance-style categories (design, code, etc.)
-- with trades and service roles clients actually post.
-- Safe to re-run: updates by fixed id, inserts General Labor once.
-- ============================================

update public.categories set
  name = 'Cleaning & Janitorial',
  icon = 'cleaning',
  description = 'Janitors, cleaners, building maintenance'
where id = '5fe5d01c-4162-4b2b-8246-a129c2b449b6';

update public.categories set
  name = 'Factory & Warehouse',
  icon = 'factory',
  description = 'Factory workers, packers, warehouse staff'
where id = '82e7a92a-d62b-4126-b91f-50691561a957';

update public.categories set
  name = 'Skilled Trades',
  icon = 'trades',
  description = 'Craftsmen, carpenters, electricians, plumbers'
where id = '86c8a1d0-7727-4bad-bf6d-0a82d35853e7';

update public.categories set
  name = 'Beauty & Salon',
  icon = 'beauty',
  description = 'Hairdressers, barbers, nail techs, stylists'
where id = '9bb2e5b2-82df-4fa5-876d-6d4f8fef0c8d';

update public.categories set
  name = 'Food Service',
  icon = 'food',
  description = 'Waiters, cooks, bakers, kitchen staff'
where id = 'b4cb5ff2-dd4c-46a2-b494-2ff9f0ae1525';

update public.categories set
  name = 'Retail & Sales',
  icon = 'retail',
  description = 'Cashiers, shop assistants, floor staff'
where id = 'dca7e643-f32a-4b6f-9831-34398dbb80da';

update public.categories set
  name = 'Delivery & Driving',
  icon = 'delivery',
  description = 'Drivers, couriers, delivery helpers'
where id = 'f9abaa48-56cf-4265-9332-50b4cae6323a';

insert into public.categories (name, icon, description)
select 'General Labor', 'labor', 'Construction helpers, movers, handyman, onsite helpers'
where not exists (
  select 1 from public.categories where icon = 'labor' and name = 'General Labor'
);
