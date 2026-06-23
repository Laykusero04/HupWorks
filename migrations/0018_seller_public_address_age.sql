-- ============================================
-- Migration 0018 — Public address + age fields on seller_profiles
-- Address is public; DOB stays owner-only in seller_private_details.
-- birth_year/month/day on seller_profiles powers public age display.
-- ============================================

alter table public.seller_profiles
  add column if not exists address text,
  add column if not exists birth_year int,
  add column if not exists birth_month int,
  add column if not exists birth_day int;

-- Migrate address from private details
update public.seller_profiles sp
set address = pd.street_address
from public.seller_private_details pd
where sp.user_id = pd.user_id
  and pd.street_address is not null
  and trim(pd.street_address) <> ''
  and (sp.address is null or trim(sp.address) = '');

-- Migrate birth date parts for public age calculation
update public.seller_profiles sp
set
  birth_year = extract(year from pd.date_of_birth)::int,
  birth_month = extract(month from pd.date_of_birth)::int,
  birth_day = extract(day from pd.date_of_birth)::int
from public.seller_private_details pd
where sp.user_id = pd.user_id
  and pd.date_of_birth is not null
  and sp.birth_year is null;
