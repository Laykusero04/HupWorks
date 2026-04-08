-- ============================================
-- HupWorks - Full Supabase Database Schema
-- ============================================
-- Run this in Supabase Dashboard > SQL Editor
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
  created_at timestamptz default now()
);

alter table public.categories enable row level security;

create policy "Categories are viewable by everyone"
  on categories for select using (true);

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
  service_id uuid references public.services(id) not null,
  client_id uuid references public.profiles(id) not null,
  seller_id uuid references public.profiles(id) not null,
  status text default 'pending' check (status in ('active', 'pending', 'completed', 'cancelled', 'delivered')),
  price numeric(10,2) not null,
  requirements_response jsonb,
  delivery_deadline timestamptz,
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
  deadline timestamptz,
  status text default 'open' check (status in ('open', 'closed')),
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
  delivery_time int not null, -- in days
  cover_letter text,
  status text default 'pending' check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz default now()
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
  service_id uuid references public.services(id) on delete cascade not null,
  rating int not null check (rating >= 1 and rating <= 5),
  comment text,
  created_at timestamptz default now()
);

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
  service_id uuid references public.services(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique (user_id, service_id)
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

-- ============================================
-- SEED DATA: Default Categories
-- ============================================

insert into public.categories (name, icon, description) values
  ('Graphics Design', 'design', 'Logo design, illustrations, and more'),
  ('Video Editing', 'video', 'Video production and editing services'),
  ('Digital Marketing', 'marketing', 'SEO, social media, and ad campaigns'),
  ('Business', 'business', 'Business plans, consulting, and strategy'),
  ('Writing & Translation', 'writing', 'Content writing, copywriting, and translations'),
  ('Programming', 'code', 'Web, mobile, and software development'),
  ('Lifestyle', 'lifestyle', 'Coaching, fitness, and personal services');
