-- ============================================
-- Migration 0050 — cause linked to platform share
-- Saves which cause a profile wants associated with their share.
-- Does not move money and does not change the share percentage.
-- ============================================

alter table public.profiles
  add column if not exists charity_cause text;

do $$
begin
  alter table public.profiles
    add constraint profiles_charity_cause_check
    check (
      charity_cause is null
      or charity_cause in ('food', 'education', 'health', 'shelter')
    );
exception
  when duplicate_object then null;
end $$;

comment on column public.profiles.charity_cause is
  'Optional cause linked to the profile share. Null means none. No payout is sent.';
