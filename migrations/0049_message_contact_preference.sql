-- ============================================
-- Migration 0049 — Who can message me (contact preference)
-- Values: everyone | hired_only | nobody
-- Existing threads always remain open; preference gates NEW conversations.
-- Soft block/report remains the hard stop (checked separately in app + 0039).
-- ============================================

alter table public.profiles
  add column if not exists message_contact_preference text not null default 'everyone';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_message_contact_preference_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_message_contact_preference_check
      check (message_contact_preference in ('everyone', 'hired_only', 'nobody'));
  end if;
end $$;

-- True when [p_user_a] and [p_user_b] share any hire (any order status).
create or replace function public.pair_has_any_hire(
  p_user_a uuid,
  p_user_b uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.orders o
    where (o.client_id = p_user_a and o.seller_id = p_user_b)
       or (o.client_id = p_user_b and o.seller_id = p_user_a)
  );
$$;

revoke all on function public.pair_has_any_hire(uuid, uuid) from public;
grant execute on function public.pair_has_any_hire(uuid, uuid) to authenticated;
grant execute on function public.pair_has_any_hire(uuid, uuid) to service_role;

-- Whether the signed-in user may start a NEW conversation with [p_other_user_id].
-- Does not consider soft-blocks (app checks those separately).
create or replace function public.can_start_conversation(p_other_user_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_pref text;
begin
  if v_me is null then
    return false;
  end if;
  if p_other_user_id is null or p_other_user_id = v_me then
    return false;
  end if;

  select coalesce(message_contact_preference, 'everyone')
  into v_pref
  from public.profiles
  where id = p_other_user_id;

  if v_pref is null then
    -- Missing profile: allow (insert will fail elsewhere)
    return true;
  end if;

  if v_pref = 'everyone' then
    return true;
  end if;

  if v_pref = 'nobody' then
    return false;
  end if;

  -- hired_only
  return public.pair_has_any_hire(v_me, p_other_user_id);
end;
$$;

revoke all on function public.can_start_conversation(uuid) from public;
grant execute on function public.can_start_conversation(uuid) to authenticated;
grant execute on function public.can_start_conversation(uuid) to service_role;

-- Server-side gate on NEW conversation inserts.
create or replace function public.enforce_message_contact_preference()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_other uuid;
  v_pref text;
begin
  -- Service role / system paths (no JWT) skip preference enforcement.
  if v_me is null then
    return new;
  end if;

  if new.client_id = v_me then
    v_other := new.seller_id;
  elsif new.seller_id = v_me then
    v_other := new.client_id;
  else
    raise exception 'Not a conversation participant';
  end if;

  select coalesce(message_contact_preference, 'everyone')
  into v_pref
  from public.profiles
  where id = v_other;

  if v_pref is null or v_pref = 'everyone' then
    return new;
  end if;

  if v_pref = 'nobody' then
    raise exception 'MESSAGING_PREFERENCE_DENIED:nobody';
  end if;

  if v_pref = 'hired_only'
     and not public.pair_has_any_hire(new.client_id, new.seller_id) then
    raise exception 'MESSAGING_PREFERENCE_DENIED:hired_only';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_message_contact_preference on public.conversations;
create trigger trg_enforce_message_contact_preference
  before insert on public.conversations
  for each row
  execute function public.enforce_message_contact_preference();
