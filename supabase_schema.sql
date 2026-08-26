-- ============================================
-- HupWorks - Full Supabase Database Schema (REFERENCE / NEW PROJECT ONLY)
-- ============================================
-- DO NOT run this entire file on a Supabase project that already has tables.
-- You will get errors like: relation "profiles" already exists (42P07).
--
-- Use instead:
--   • Existing project: run only the numbered scripts in /migrations/ (0001,
--     0002, …) in order, or run the specific migration you need.
--   • Brand-new empty database: this file can create everything from scratch.
--
-- Supabase-hosted projects usually already include auth + often a starter
-- schema — apply incremental migrations only.
-- ============================================

-- ==================
-- 1. PROFILES
-- ==================

create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  role text not null check (role in ('client', 'seller')),
  name text not null,
  email text not null,
  phone text,
  country text,
  city text,
  gender text,
  profile_image_url text,
  bio text,
  rating numeric(2,1) default 0,
  balance numeric(12,2) default 0,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone"
  on profiles for select using (true);

create policy "Users can update their own profile"
  on profiles for update using (auth.uid() = id);

create policy "Users can insert their own profile"
  on profiles for insert with check (auth.uid() = id);

-- ==================
-- 2. SELLER PROFILES
-- ==================

create table public.seller_profiles (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null unique,
  skills text[] default '{}',
  skill_level text,
  languages text[] default '{}',
  language_level text,
  education text,
  experience text,
  about text,
  impressions_count int default 0,
  interactions_count int default 0,
  reach_count int default 0,
  created_at timestamptz default now()
);

alter table public.seller_profiles enable row level security;

create policy "Seller profiles are viewable by everyone"
  on seller_profiles for select using (true);

create policy "Sellers can update their own seller profile"
  on seller_profiles for update using (auth.uid() = user_id);

create policy "Sellers can insert their own seller profile"
  on seller_profiles for insert with check (auth.uid() = user_id);

-- ==================
-- 3. CATEGORIES
-- ==================

create table public.categories (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  icon text,
  description text,
  is_custom boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now()
);

create unique index categories_name_lower_unique on public.categories (lower(trim(name)));

alter table public.categories enable row level security;

create policy "Categories are viewable by everyone"
  on categories for select using (true);

create policy "Authenticated users can insert custom categories"
  on public.categories for insert to authenticated
  with check (is_custom = true and created_by = auth.uid());

-- ==================
-- 4. SUB-CATEGORIES
-- ==================

create table public.sub_categories (
  id uuid default gen_random_uuid() primary key,
  category_id uuid references public.categories(id) on delete cascade not null,
  name text not null,
  created_at timestamptz default now()
);

alter table public.sub_categories enable row level security;

create policy "Sub-categories are viewable by everyone"
  on sub_categories for select using (true);

-- ==================
-- 5. SERVICES
-- ==================

create table public.services (
  id uuid default gen_random_uuid() primary key,
  seller_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  description text,
  category_id uuid references public.categories(id),
  sub_category_id uuid references public.sub_categories(id),
  service_type text check (service_type in ('online', 'offline')),
  price numeric(10,2) not null,
  delivery_time int not null, -- in days
  revision_count int default 0,
  images text[] default '{}',
  status text default 'active' check (status in ('active', 'paused')),
  rating numeric(2,1) default 0,
  review_count int default 0,
  created_at timestamptz default now()
);

alter table public.services enable row level security;

create policy "Services are viewable by everyone"
  on services for select using (true);

create policy "Sellers can insert their own services"
  on services for insert with check (auth.uid() = seller_id);

create policy "Sellers can update their own services"
  on services for update using (auth.uid() = seller_id);

create policy "Sellers can delete their own services"
  on services for delete using (auth.uid() = seller_id);

-- ==================
-- 6. SERVICE REQUIREMENTS
-- ==================

create table public.service_requirements (
  id uuid default gen_random_uuid() primary key,
  service_id uuid references public.services(id) on delete cascade not null,
  question text not null,
  is_required boolean default true,
  created_at timestamptz default now()
);

alter table public.service_requirements enable row level security;

create policy "Service requirements are viewable by everyone"
  on service_requirements for select using (true);

create policy "Sellers can manage their service requirements"
  on service_requirements for insert with check (
    auth.uid() = (select seller_id from services where id = service_id)
  );

create policy "Sellers can update their service requirements"
  on service_requirements for update using (
    auth.uid() = (select seller_id from services where id = service_id)
  );

create policy "Sellers can delete their service requirements"
  on service_requirements for delete using (
    auth.uid() = (select seller_id from services where id = service_id)
  );

-- ==================
-- 7. ORDERS
-- ==================

create table public.orders (
  id uuid default gen_random_uuid() primary key,
  -- service_id is nullable: contracts created from job_offers have no service
  service_id uuid references public.services(id),
  client_id uuid references public.profiles(id) not null,
  seller_id uuid references public.profiles(id) not null,
  status text default 'pending' check (status in ('active', 'pending', 'completed', 'cancelled', 'delivered')),
  price numeric(10,2) not null,
  requirements_response jsonb,
  delivery_deadline timestamptz,
  job_offer_id uuid, -- FK added after job_offers is created (see below)
  created_at timestamptz default now(),
  completed_at timestamptz
);

alter table public.orders enable row level security;

create policy "Users can view their own orders"
  on orders for select using (auth.uid() = client_id or auth.uid() = seller_id);

create policy "Clients can create orders"
  on orders for insert with check (auth.uid() = client_id);

create policy "Order participants can update orders"
  on orders for update using (auth.uid() = client_id or auth.uid() = seller_id);

-- ==================
-- 8. ORDER DELIVERIES
-- ==================

create table public.order_deliveries (
  id uuid default gen_random_uuid() primary key,
  order_id uuid references public.orders(id) on delete cascade not null,
  message text,
  attachment_url text,
  delivered_at timestamptz default now()
);

alter table public.order_deliveries enable row level security;

create policy "Order participants can view deliveries"
  on order_deliveries for select using (
    auth.uid() in (select client_id from orders where id = order_id)
    or auth.uid() in (select seller_id from orders where id = order_id)
  );

create policy "Sellers can create deliveries"
  on order_deliveries for insert with check (
    auth.uid() in (select seller_id from orders where id = order_id)
  );

-- ==================
-- 9. JOB POSTS
-- ==================

create table public.job_posts (
  id uuid default gen_random_uuid() primary key,
  client_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  description text,
  category_id uuid references public.categories(id),
  budget_min numeric(10,2),
  budget_max numeric(10,2),
  budget_basis text not null default 'fixed' check (budget_basis in ('fixed', 'per_hour', 'per_day', 'per_month')),
  deadline timestamptz,
  status text default 'open' check (status in ('open', 'closed')),
  job_type text not null default 'gig' check (job_type in ('gig', 'full_time', 'part_time')),
  location text,
  location_type text check (location_type in ('On-site', 'Remote')),
  attendance_mode text not null default 'qr_in_out'
    check (attendance_mode in ('qr_in_out', 'qr_once', 'self_report', 'disabled')),
  latitude double precision,
  longitude double precision,
  workers_needed int not null default 1 check (workers_needed >= 1),
  created_at timestamptz default now()
);

alter table public.job_posts enable row level security;

create policy "Job posts are viewable by everyone"
  on job_posts for select using (true);

create policy "Clients can create job posts"
  on job_posts for insert with check (auth.uid() = client_id);

create policy "Clients can update their own job posts"
  on job_posts for update using (auth.uid() = client_id);

create policy "Clients can delete their own job posts"
  on job_posts for delete using (auth.uid() = client_id);

-- ==================
-- 10. JOB OFFERS
-- ==================

create table public.job_offers (
  id uuid default gen_random_uuid() primary key,
  job_post_id uuid references public.job_posts(id) on delete cascade not null,
  seller_id uuid references public.profiles(id) on delete cascade not null,
  price numeric(10,2) not null,
  price_basis text not null default 'fixed' check (price_basis in ('fixed', 'per_hour', 'per_day', 'per_month')),
  delivery_time int,
  delivery_time_unit text,
  cover_letter text,
  status text default 'pending' check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz default now(),
  constraint job_offers_delivery_pair_check check (
    (delivery_time is null and delivery_time_unit is null)
    or (
      delivery_time is not null
      and delivery_time > 0
      and delivery_time_unit in ('hours', 'days')
    )
  )
);

alter table public.job_offers enable row level security;

create policy "Job offer participants can view offers"
  on job_offers for select using (
    auth.uid() = seller_id
    or auth.uid() in (select client_id from job_posts where id = job_post_id)
  );

create policy "Sellers can create offers"
  on job_offers for insert with check (auth.uid() = seller_id);

create policy "Offer participants can update offers"
  on job_offers for update using (
    auth.uid() = seller_id
    or auth.uid() in (select client_id from job_posts where id = job_post_id)
  );

-- Deferred FK from orders.job_offer_id (orders is defined before job_offers).
alter table public.orders
  add constraint orders_job_offer_id_fkey
  foreign key (job_offer_id) references public.job_offers(id) on delete set null;

create index if not exists orders_job_offer_id_idx on public.orders(job_offer_id);

-- ==================
-- 11. CONVERSATIONS
-- ==================

create table public.conversations (
  id uuid default gen_random_uuid() primary key,
  client_id uuid references public.profiles(id) on delete cascade not null,
  seller_id uuid references public.profiles(id) on delete cascade not null,
  last_message text,
  last_message_at timestamptz default now(),
  unique (client_id, seller_id)
);

alter table public.conversations enable row level security;

create policy "Participants can view their conversations"
  on conversations for select using (auth.uid() = client_id or auth.uid() = seller_id);

create policy "Authenticated users can create conversations"
  on conversations for insert with check (auth.uid() = client_id or auth.uid() = seller_id);

create policy "Participants can update their conversations"
  on conversations for update using (auth.uid() = client_id or auth.uid() = seller_id);

-- ==================
-- 12. MESSAGES
-- ==================

create table public.messages (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  content text,
  attachment_url text,
  read boolean default false,
  created_at timestamptz default now()
);

alter table public.messages enable row level security;

create policy "Conversation participants can view messages"
  on messages for select using (
    auth.uid() in (
      select client_id from conversations where id = conversation_id
      union
      select seller_id from conversations where id = conversation_id
    )
  );

create policy "Conversation participants can send messages"
  on messages for insert with check (
    auth.uid() = sender_id
    and auth.uid() in (
      select client_id from conversations where id = conversation_id
      union
      select seller_id from conversations where id = conversation_id
    )
  );

create policy "Recipients can mark messages as read"
  on messages for update using (
    auth.uid() in (
      select client_id from conversations where id = conversation_id
      union
      select seller_id from conversations where id = conversation_id
    )
  );

-- Enable Realtime for messages
alter publication supabase_realtime add table messages;

-- ==================
-- 13. REVIEWS
-- ==================

create table public.reviews (
  id uuid default gen_random_uuid() primary key,
  order_id uuid references public.orders(id) on delete cascade not null,
  reviewer_id uuid references public.profiles(id) on delete cascade not null,
  reviewed_id uuid references public.profiles(id) on delete cascade not null,
  service_id uuid references public.services(id) on delete cascade,
  job_offer_id uuid references public.job_offers(id) on delete set null,
  rating int not null check (rating >= 1 and rating <= 5),
  comment text,
  created_at timestamptz default now()
);

create index if not exists reviews_job_offer_id_idx on public.reviews(job_offer_id);

create unique index if not exists reviews_order_reviewer_unique
  on public.reviews (order_id, reviewer_id);

alter table public.reviews enable row level security;

create policy "Reviews are viewable by everyone"
  on reviews for select using (true);

create policy "Order participants can create reviews"
  on reviews for insert with check (
    auth.uid() = reviewer_id
    and auth.uid() in (
      select client_id from orders where id = order_id
      union
      select seller_id from orders where id = order_id
    )
  );

-- ==================
-- 14. FAVOURITES
-- ==================

create table public.favourites (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  job_post_id uuid references public.job_posts(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique (user_id, job_post_id)
);

alter table public.favourites enable row level security;

create policy "Users can view their own favourites"
  on favourites for select using (auth.uid() = user_id);

create policy "Users can add favourites"
  on favourites for insert with check (auth.uid() = user_id);

create policy "Users can remove favourites"
  on favourites for delete using (auth.uid() = user_id);

-- ==================
-- 15. NOTIFICATIONS
-- ==================

create table public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  body text,
  type text, -- 'order', 'message', 'review', 'system'
  reference_id uuid, -- links to related order/message/etc
  read boolean default false,
  created_at timestamptz default now()
);

alter table public.notifications enable row level security;

create policy "Users can view their own notifications"
  on notifications for select using (auth.uid() = user_id);

create policy "Users can update their own notifications"
  on notifications for update using (auth.uid() = user_id);

`1create or replace function public.create_notification(
  p_user_id uuid,
  p_title text,
  p_body text default null,
  p_type text default null,
  p_reference_id uuid default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null then
    return;
  end if;
  insert into public.notifications (user_id, title, body, type, reference_id)
  values (p_user_id, p_title, p_body, p_type, p_reference_id);
end;
$$;

-- ==================
-- 16. TRANSACTIONS
-- ==================

create table public.transactions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  type text not null check (type in ('deposit', 'withdrawal', 'earning', 'payment')),
  amount numeric(10,2) not null,
  status text default 'pending' check (status in ('pending', 'completed', 'failed')),
  gateway text check (gateway in ('paypal', 'credit_card', 'bkash')),
  reference text,
  created_at timestamptz default now()
);

alter table public.transactions enable row level security;

create policy "Users can view their own transactions"
  on transactions for select using (auth.uid() = user_id);

create policy "Users can create transactions"
  on transactions for insert with check (auth.uid() = user_id);

-- ==================
-- 17. PAYMENT METHODS
-- ==================

create table public.payment_methods (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  type text not null check (type in ('paypal', 'credit_card')),
  details jsonb not null default '{}',
  is_default boolean default false,
  created_at timestamptz default now()
);

alter table public.payment_methods enable row level security;

create policy "Users can view their own payment methods"
  on payment_methods for select using (auth.uid() = user_id);

create policy "Users can add payment methods"
  on payment_methods for insert with check (auth.uid() = user_id);

create policy "Users can update their own payment methods"
  on payment_methods for update using (auth.uid() = user_id);

create policy "Users can delete their own payment methods"
  on payment_methods for delete using (auth.uid() = user_id);

-- ==================
-- 18. WITHDRAWAL REQUESTS
-- ==================

create table public.withdrawal_requests (
  id uuid default gen_random_uuid() primary key,
  seller_id uuid references public.profiles(id) on delete cascade not null,
  amount numeric(10,2) not null,
  payment_method_id uuid references public.payment_methods(id),
  status text default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz default now()
);

alter table public.withdrawal_requests enable row level security;

create policy "Sellers can view their own withdrawal requests"
  on withdrawal_requests for select using (auth.uid() = seller_id);

create policy "Sellers can create withdrawal requests"
  on withdrawal_requests for insert with check (auth.uid() = seller_id);

-- ============================================
-- AUTO-CREATE PROFILE ON SIGN UP (TRIGGER)
-- ============================================
-- This automatically creates a profile row
-- when a new user signs up via Supabase Auth.
-- The role must be passed as metadata during signUp:
--   supabase.auth.signUp(data: {'role': 'client', 'name': 'John'})
-- ============================================

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, role, name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'role', 'client'),
    coalesce(new.raw_user_meta_data->>'name', ''),
    new.email
  );

  -- If seller, also create seller_profiles row
  if coalesce(new.raw_user_meta_data->>'role', 'client') = 'seller' then
    insert into public.seller_profiles (user_id)
    values (new.id);
  end if;

  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ==================
-- HIRE ONBOARDING (per-order first-day instructions)
-- ==================

create or replace function public._hire_onboarding_default_sections()
returns jsonb
language sql
immutable
as $$
  select jsonb_build_array(
    jsonb_build_object('key', 'where', 'title', 'Where to go', 'body', ''),
    jsonb_build_object('key', 'when', 'title', 'When to arrive', 'body', ''),
    jsonb_build_object('key', 'who', 'title', 'Who to contact', 'body', ''),
    jsonb_build_object('key', 'access', 'title', 'Building access', 'body', ''),
    jsonb_build_object('key', 'rules', 'title', 'Site rules', 'body', ''),
    jsonb_build_object('key', 'attendance', 'title', 'Attendance', 'body', ''),
    jsonb_build_object('key', 'emergency', 'title', 'Emergency', 'body', '')
  );
$$;

create table public.hire_onboarding_packets (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  client_id uuid not null references public.profiles(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'draft' check (status in ('draft', 'published')),
  required_ack boolean not null default true,
  sections jsonb not null default public._hire_onboarding_default_sections(),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.hire_onboarding_packets enable row level security;

create policy "Clients manage own hire onboarding packets"
  on public.hire_onboarding_packets for all
  using (auth.uid() = client_id) with check (auth.uid() = client_id);

create policy "Sellers view published hire onboarding packets"
  on public.hire_onboarding_packets for select
  using (auth.uid() = seller_id and status = 'published');

create table public.hire_onboarding_acknowledgments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  acknowledged_at timestamptz not null default now(),
  unique (order_id, seller_id)
);

alter table public.hire_onboarding_acknowledgments enable row level security;

create policy "Order participants view hire onboarding acks"
  on public.hire_onboarding_acknowledgments for select
  using (
    auth.uid() in (
      select client_id from public.orders where id = order_id
      union
      select seller_id from public.orders where id = order_id
    )
  );

create or replace function public.create_hire_onboarding_draft(p_order_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client uuid;
  v_seller uuid;
  v_packet_id uuid;
begin
  select client_id, seller_id into v_client, v_seller from public.orders where id = p_order_id;
  if not found then raise exception 'Order not found'; end if;
  if v_client is distinct from auth.uid() then raise exception 'Not authorized'; end if;
  select id into v_packet_id from public.hire_onboarding_packets where order_id = p_order_id;
  if found then return v_packet_id; end if;
  insert into public.hire_onboarding_packets (order_id, client_id, seller_id, sections)
  values (p_order_id, v_client, v_seller, public._hire_onboarding_default_sections())
  returning id into v_packet_id;
  return v_packet_id;
end;
$$;

grant execute on function public.create_hire_onboarding_draft(uuid) to authenticated;

create or replace function public.publish_hire_onboarding(p_packet_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_packet record;
  v_job_title text;
begin
  select p.id, p.order_id, p.client_id, p.seller_id, p.status into v_packet
  from public.hire_onboarding_packets p where p.id = p_packet_id;
  if not found then raise exception 'Onboarding packet not found'; end if;
  if v_packet.client_id is distinct from auth.uid() then raise exception 'Not authorized'; end if;
  update public.hire_onboarding_packets
  set status = 'published', published_at = now(), updated_at = now() where id = p_packet_id;
  select coalesce(jp.title, 'your contract') into v_job_title
  from public.orders o
  left join public.job_offers jo on jo.id = o.job_offer_id
  left join public.job_posts jp on jp.id = jo.job_post_id
  where o.id = v_packet.order_id;
  perform public.create_notification(
    v_packet.seller_id, 'First-day instructions',
    coalesce('Read site instructions for "' || v_job_title || '".', 'Your client published first-day instructions.'),
    'hire_onboarding', v_packet.order_id
  );
end;
$$;

grant execute on function public.publish_hire_onboarding(uuid) to authenticated;

create or replace function public.acknowledge_hire_onboarding(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_seller uuid;
  v_status text;
begin
  select seller_id into v_seller from public.orders where id = p_order_id;
  if not found then raise exception 'Order not found'; end if;
  if v_seller is distinct from auth.uid() then raise exception 'Not authorized'; end if;
  select status into v_status from public.hire_onboarding_packets where order_id = p_order_id;
  if not found or v_status <> 'published' then
    raise exception 'No published instructions for this contract';
  end if;
  insert into public.hire_onboarding_acknowledgments (order_id, seller_id)
  values (p_order_id, v_seller)
  on conflict (order_id, seller_id) do update set acknowledged_at = now();
end;
$$;

grant execute on function public.acknowledge_hire_onboarding(uuid) to authenticated;

-- ============================================
-- ACCEPT JOB OFFER RPC
-- ============================================
-- Accepts one offer, creates contract. If workers_needed is a finite cap and
-- this hire fills it, closes the job. Other applications stay pending until you
-- reject them in the app. Sentinel workers_needed >= 999 = no cap (job stays open).
-- ============================================

create or replace function public.accept_job_offer(p_offer_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post_id uuid;
  v_client uuid;
  v_seller uuid;
  v_price numeric;
  v_delivery_time int;
  v_delivery_time_unit text;
  v_workers_needed int;
  v_offer_status text;
  v_job_status text;
  v_deadline timestamptz;
  v_unit text;
  v_accepted_before int;
  v_accepted_after int;
  v_order_id uuid;
  v_job_title text;
begin
  select
    jo.job_post_id,
    jo.seller_id,
    jo.price,
    jo.delivery_time,
    jo.delivery_time_unit,
    jp.client_id,
    jp.workers_needed,
    jo.status,
    jp.status,
    jp.title
  into
    v_post_id,
    v_seller,
    v_price,
    v_delivery_time,
    v_delivery_time_unit,
    v_client,
    v_workers_needed,
    v_offer_status,
    v_job_status,
    v_job_title
  from public.job_offers jo
  join public.job_posts jp on jp.id = jo.job_post_id
  where jo.id = p_offer_id;

  if not found then
    raise exception 'Offer not found';
  end if;

  if v_client is distinct from auth.uid() then
    raise exception 'Not authorized';
  end if;

  if lower(coalesce(v_job_status, '')) <> 'open' then
    raise exception 'This job is not open for new hires';
  end if;

  if lower(coalesce(v_offer_status, '')) <> 'pending' then
    raise exception 'This application is not pending';
  end if;

  v_workers_needed := greatest(1, coalesce(v_workers_needed, 1));

  select count(*)::int into v_accepted_before
  from public.job_offers
  where job_post_id = v_post_id and lower(status) = 'accepted';

  if v_workers_needed < 999 then
    if v_accepted_before >= v_workers_needed then
      raise exception 'Hiring limit reached for this job';
    end if;
  end if;

  if v_delivery_time is null then
    v_deadline := null;
  else
    v_unit := lower(trim(coalesce(v_delivery_time_unit, 'days')));
    if v_unit = 'hours' then
      v_deadline := now() + make_interval(hours => greatest(1, v_delivery_time));
    else
      v_deadline := now() + make_interval(days => greatest(1, v_delivery_time));
    end if;
  end if;

  update public.job_offers set status = 'accepted' where id = p_offer_id;

  select count(*)::int into v_accepted_after
  from public.job_offers
  where job_post_id = v_post_id and lower(status) = 'accepted';

  if v_workers_needed < 999 and v_accepted_after >= v_workers_needed then
    update public.job_posts set status = 'closed' where id = v_post_id;
  end if;

  insert into public.orders
    (job_offer_id, client_id, seller_id, price, status, delivery_deadline)
  values
    (p_offer_id, v_client, v_seller, v_price, 'pending', v_deadline)
  returning id into v_order_id;

  perform public.create_notification(
    v_seller,
    'Application accepted',
    coalesce('Your application for "' || v_job_title || '" was accepted.', 'Your application was accepted.'),
    'order',
    v_order_id
  );

  perform public.create_hire_onboarding_draft(v_order_id);

  return v_order_id;
end;
$$;

grant execute on function public.accept_job_offer(uuid) to authenticated;

-- ============================================
-- SEED DATA: Default Categories
-- ============================================

insert into public.categories (name, icon, description) values
  ('Cleaning & Janitorial', 'cleaning', 'Janitors, cleaners, building maintenance'),
  ('Factory & Warehouse', 'factory', 'Factory workers, packers, warehouse staff'),
  ('Skilled Trades', 'trades', 'Craftsmen, carpenters, electricians, plumbers'),
  ('Beauty & Salon', 'beauty', 'Hairdressers, barbers, nail techs, stylists'),
  ('Food Service', 'food', 'Waiters, cooks, bakers, kitchen staff'),
  ('Retail & Sales', 'retail', 'Cashiers, shop assistants, floor staff'),
  ('Delivery & Driving', 'delivery', 'Drivers, couriers, delivery helpers'),
  ('General Labor', 'labor', 'Construction helpers, movers, handyman, onsite helpers');
