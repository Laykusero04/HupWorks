-- Freelancer account onboarding gate (post email/password signup).
-- Existing sellers are marked complete so they are not locked into the new flow.

alter table public.profiles
  add column if not exists seller_onboarding_completed boolean not null default false;

update public.profiles
set seller_onboarding_completed = true
where role = 'seller'
  and seller_onboarding_completed = false;
