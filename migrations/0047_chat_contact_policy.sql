-- ============================================
-- Migration 0047 — Who can start a chat
-- Profiles choose which other profiles may open a new conversation.
-- Existing threads and open contracts stay reachable.
-- ============================================

alter table public.profiles
  add column if not exists chat_contact_policy text not null default 'anyone';

do $$
begin
  alter table public.profiles
    add constraint profiles_chat_contact_policy_check
    check (chat_contact_policy in ('anyone', 'verified', 'connections', 'nobody'));
exception
  when duplicate_object then null;
end $$;

comment on column public.profiles.chat_contact_policy is
  'Who may start a new chat: anyone, verified, connections (shared application or contract), nobody.';

-- Shared application or any contract between the pair.
create or replace function public.pair_has_work_connection(
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
  )
  or exists (
    select 1
    from public.job_offers jo
    join public.job_posts jp on jp.id = jo.job_post_id
    where (
        (jp.client_id = p_user_a and jo.seller_id = p_user_b)
        or (jp.client_id = p_user_b and jo.seller_id = p_user_a)
      )
      and lower(coalesce(jo.status, '')) <> 'withdrawn'
  );
$$;

-- Decision for auth.uid() starting a chat with p_recipient.
-- allowed=true, or reason in blocked | nobody | verified | connections.
create or replace function public.chat_contact_decision(p_recipient uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_sender uuid := auth.uid();
  v_policy text;
  v_verified text;
begin
  if v_sender is null then
    return jsonb_build_object('allowed', false, 'reason', 'unauthenticated');
  end if;
  if p_recipient is null or p_recipient = v_sender then
    return jsonb_build_object('allowed', false, 'reason', 'invalid');
  end if;

  if exists (
    select 1
    from public.conversations c
    where (c.client_id = v_sender and c.seller_id = p_recipient)
       or (c.client_id = p_recipient and c.seller_id = v_sender)
  ) then
    return jsonb_build_object('allowed', true, 'reason', 'existing');
  end if;

  if public.pair_contact_blocked(v_sender, p_recipient) then
    return jsonb_build_object('allowed', false, 'reason', 'blocked');
  end if;

  if public.pair_has_open_obligation(v_sender, p_recipient) then
    return jsonb_build_object('allowed', true, 'reason', 'obligation');
  end if;

  select coalesce(p.chat_contact_policy, 'anyone')
    into v_policy
  from public.profiles p
  where p.id = p_recipient;

  v_policy := coalesce(v_policy, 'anyone');

  if v_policy = 'anyone' then
    return jsonb_build_object('allowed', true, 'reason', 'anyone');
  end if;

  if v_policy = 'nobody' then
    return jsonb_build_object('allowed', false, 'reason', 'nobody');
  end if;

  if v_policy = 'verified' then
    select coalesce(p.verification_status, 'unverified')
      into v_verified
    from public.profiles p
    where p.id = v_sender;
    if v_verified = 'verified'
        or public.pair_has_work_connection(v_sender, p_recipient) then
      return jsonb_build_object('allowed', true, 'reason', 'verified');
    end if;
    return jsonb_build_object('allowed', false, 'reason', 'verified');
  end if;

  if v_policy = 'connections'
      and public.pair_has_work_connection(v_sender, p_recipient) then
    return jsonb_build_object('allowed', true, 'reason', 'connection');
  end if;

  if v_policy = 'connections' then
    return jsonb_build_object('allowed', false, 'reason', 'connections');
  end if;

  return jsonb_build_object('allowed', true, 'reason', 'anyone');
end;
$$;

revoke all on function public.pair_has_work_connection(uuid, uuid) from public;
revoke all on function public.chat_contact_decision(uuid) from public;
grant execute on function public.pair_has_work_connection(uuid, uuid) to authenticated;
grant execute on function public.chat_contact_decision(uuid) to authenticated;

create or replace function public.enforce_chat_contact_policy()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sender uuid := auth.uid();
  v_recipient uuid;
  v_decision jsonb;
  v_reason text;
begin
  if v_sender is null then
    raise exception 'Not authenticated';
  end if;

  if v_sender = new.client_id then
    v_recipient := new.seller_id;
  elsif v_sender = new.seller_id then
    v_recipient := new.client_id;
  else
    raise exception 'Not a participant';
  end if;

  v_decision := public.chat_contact_decision(v_recipient);
  if coalesce((v_decision ->> 'allowed')::boolean, false) is distinct from true then
    v_reason := coalesce(v_decision ->> 'reason', 'denied');
    if v_reason = 'blocked' then
      raise exception 'Contact blocked';
    end if;
    raise exception 'Chat privacy: %', v_reason;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_chat_contact_policy on public.conversations;
create trigger trg_enforce_chat_contact_policy
  before insert on public.conversations
  for each row
  execute function public.enforce_chat_contact_policy();
