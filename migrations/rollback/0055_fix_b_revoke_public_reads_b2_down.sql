-- Rollback for 0055 (B2): restores today's (open) read access immediately.
begin;
grant select on public.profiles to anon, authenticated;
grant select on public.seller_profiles to anon, authenticated;
commit;
