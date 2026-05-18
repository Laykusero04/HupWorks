-- ============================================
-- Migration 0012 — Fix attendance token generation
-- Run if 0011 failed with: gen_random_bytes(integer) does not exist
-- (pgcrypto extension not enabled on the project)
-- ============================================

create or replace function public._attendance_new_token()
returns text
language sql
as $$
  select replace(gen_random_uuid()::text, '-', '')
      || replace(gen_random_uuid()::text, '-', '');
$$;
