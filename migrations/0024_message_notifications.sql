-- ============================================
-- Migration 0024 — Message push/in-app notifications
-- Notify recipient on new chat message with optional order/job context
-- ============================================

create or replace function public.notify_message_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client_id uuid;
  v_seller_id uuid;
  v_recipient uuid;
  v_sender_name text;
  v_context text;
  v_order_id uuid;
  v_job_title text;
  v_body text;
  v_preview text;
begin
  select c.client_id, c.seller_id
    into v_client_id, v_seller_id
    from public.conversations c
    where c.id = new.conversation_id;

  if not found then
    return new;
  end if;

  if new.sender_id = v_client_id then
    v_recipient := v_seller_id;
  elsif new.sender_id = v_seller_id then
    v_recipient := v_client_id;
  else
    return new;
  end if;

  if v_recipient is null or v_recipient = new.sender_id then
    return new;
  end if;

  select p.name into v_sender_name
    from public.profiles p
    where p.id = new.sender_id;

  select o.id,
         coalesce(jp.title, s.title)
    into v_order_id, v_job_title
    from public.orders o
    left join public.job_offers jo on jo.id = o.job_offer_id
    left join public.job_posts jp on jp.id = jo.job_post_id
    left join public.services s on s.id = o.service_id
    where o.client_id = v_client_id
      and o.seller_id = v_seller_id
      and lower(coalesce(o.status, '')) not in ('completed', 'cancelled')
    order by o.created_at desc
    limit 1;

  if v_job_title is not null and trim(v_job_title) <> '' then
    v_context := trim(v_job_title);
  elsif v_order_id is not null then
    v_context := 'Order #' || upper(substring(v_order_id::text, 1, 8));
  end if;

  v_preview := left(trim(coalesce(new.content, '')), 120);
  if v_preview = '' and new.attachment_url is not null then
    v_preview := 'Sent an attachment';
  end if;

  if v_context is not null then
    v_body := 'You have a new message about "' || v_context || '".';
    if v_preview <> '' then
      v_body := v_body || ' "' || v_preview || '"';
    end if;
  elsif v_preview <> '' then
    v_body := v_preview;
  else
    v_body := 'You have a new message.';
  end if;

  perform public.create_notification(
    v_recipient,
    coalesce(nullif(trim(v_sender_name), ''), 'New message'),
    v_body,
    'message',
    new.conversation_id
  );

  return new;
end;
$$;

drop trigger if exists trg_notify_message_insert on public.messages;
create trigger trg_notify_message_insert
  after insert on public.messages
  for each row
  execute function public.notify_message_insert();
