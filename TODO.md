# HupWorks - Supabase Backend Integration TODO

> All UI screens are built with hardcoded/mock data. This document outlines everything needed to wire the app to a real Supabase backend.

---

## 1. Supabase Project Setup

- [x] Create Supabase project
- [x] Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to `.env`
- [x] Enable Row Level Security (RLS) on all tables
- [x] Set up Supabase Storage buckets for images (profile pictures, service images, chat attachments)

---

## 2. Database Tables to Create

### Users / Profiles
- [x] `profiles` table — id (FK to auth.users), role (`client` | `seller`), name, email, phone, country, city, gender, profile_image_url, bio, rating, balance, created_at
- [x] `seller_profiles` table — user_id (FK), skills, skill_level, languages, language_level, education, experience, about, impressions_count, interactions_count, reach_count

### Services
- [x] `categories` table — id, name, icon, description
- [x] `sub_categories` table — id, category_id (FK), name
- [x] `services` table — id, seller_id (FK), title, description, category_id (FK), sub_category_id (FK), service_type (online/offline), price, delivery_time, revision_count, images (array), status (active/paused), rating, review_count, created_at
- [x] `service_requirements` table — id, service_id (FK), question, is_required

### Orders
- [x] `orders` table — id, service_id (FK), client_id (FK), seller_id (FK), status (active/pending/completed/cancelled/delivered), price, requirements_response, delivery_deadline, created_at, completed_at
- [x] `order_deliveries` table — id, order_id (FK), message, attachment_url, delivered_at

### Jobs (Client Job Posts)
- [x] `job_posts` table — id, client_id (FK), title, description, category_id (FK), budget_min, budget_max, deadline, status (open/closed), created_at
- [x] `job_offers` table — id, job_post_id (FK), seller_id (FK), price, delivery_time, cover_letter, status (pending/accepted/rejected), created_at

### Chat / Messaging
- [x] `conversations` table — id, client_id (FK), seller_id (FK), last_message, last_message_at
- [x] `messages` table — id, conversation_id (FK), sender_id (FK), content, attachment_url, read, created_at
- [x] Enable Supabase Realtime on `messages` table

### Reviews
- [x] `reviews` table — id, order_id (FK), reviewer_id (FK), reviewed_id (FK), service_id (FK), rating (1-5), comment, created_at

### Favourites
- [x] `favourites` table — id, user_id (FK), service_id (FK), created_at

### Notifications
- [x] `notifications` table — id, user_id (FK), title, body, type, reference_id, read, created_at

### Financial
- [x] `transactions` table — id, user_id (FK), type (deposit/withdrawal/earning/payment), amount, status, gateway (paypal/credit_card/bkash), reference, created_at
- [x] `payment_methods` table — id, user_id (FK), type (paypal/credit_card), details (jsonb), is_default, created_at
- [x] `withdrawal_requests` table — id, seller_id (FK), amount, payment_method_id (FK), status (pending/approved/rejected), created_at

---

## 3. Authentication

- [x] Wire **Client Sign Up** screen to `supabase.auth.signUp()` with email/password
- [x] Wire **Seller Sign Up** screen to `supabase.auth.signUp()` with email/password
- [x] Wire **Client Login** / **Seller Login** to `supabase.auth.signInWithPassword()`
- [x] Wire **Forgot Password** screens to `supabase.auth.resetPasswordForEmail()`
- [ ] Wire **OTP Verification** screen to `supabase.auth.verifyOTP()` *(skipped — confirm email is OFF)*
- [x] Create `profiles` row on sign-up via Supabase trigger or app logic
- [x] Store user role (client/seller) in profile on registration
- [x] Handle auth state persistence (auto-login on app restart)
- [x] Add logout functionality (`supabase.auth.signOut()`)

---

## 4. Client Screens - Data Integration

### Client Home Screen
- [x] Fetch user profile (name, balance) from `profiles`
- [x] Fetch `categories` list from DB
- [x] Fetch popular/trending services from `services` (sorted by rating/orders)
- [x] Fetch top sellers from `seller_profiles` (sorted by rating)
- [x] Fetch recently viewed services (local storage or DB)
- [x] Wire search bar to query `services` table

### Client Service Details
- [x] Fetch full service data + seller info by service ID
- [x] Fetch reviews for the service from `reviews`
- [x] Fetch service requirements from `service_requirements`
- [x] Implement "Add to Favourites" toggle (insert/delete `favourites`)

### Client Orders
- [x] Create order on "Order Now" (insert into `orders`)
- [x] Fetch client orders filtered by status (active/pending/completed/cancelled)
- [x] Show real order details (service name, seller, price, deadline countdown)
- [ ] Submit requirements response after ordering

### Client Job Posts
- [x] Fetch client's job posts from `job_posts`
- [x] Create new job post (insert into `job_posts`)
- [x] Fetch seller offers on a job from `job_offers`
- [x] Accept/reject offers

### Client Profile
- [x] Fetch and display profile data from `profiles`
- [x] Update profile (name, email, phone, country, image)
- [x] Upload profile image to Supabase Storage

### Client Favourites
- [x] Fetch favourited services from `favourites` joined with `services`

### Client Dashboard
- [x] Fetch order stats (total spent, active orders, completed orders)

### Client Notifications
- [x] Fetch notifications from `notifications` table
- [x] Mark notifications as read

### Client Deposit / Transaction
- [x] Fetch transaction history from `transactions`
- [x] Handle deposit flow (insert transaction record)

---

## 5. Seller Screens - Data Integration

### Seller Home Screen (Dashboard)
- [x] Fetch seller performance metrics (impressions, interactions, reach)
- [x] Fetch earnings data for chart (from `transactions` where type = earning)
- [x] Support period filtering (Last Month / This Month)

### Seller My Services
- [x] Fetch seller's services from `services` where seller_id = current user
- [x] Edit existing service
- [x] Delete / pause service

### Create New Service (3-step wizard)
- [x] Step 1: Save title, category, sub-category, service type, price, delivery time, revisions
- [x] Step 2: Upload service images to Supabase Storage
- [x] Step 3: Add service requirements
- [x] Insert complete service into `services` table

### Seller Orders
- [x] Fetch seller orders filtered by status
- [x] Update order status (accept, deliver, complete)
- [x] Deliver order (upload attachment, send delivery message)

### Seller Buyer Requests
- [x] Fetch open job posts relevant to seller's categories from `job_posts`
- [x] Create offer on a job post (insert into `job_offers`)

### Seller Profile
- [x] Fetch and display seller profile + seller_profiles data
- [x] Update profile details
- [x] Upload profile image to Supabase Storage

### Seller Payment Methods
- [ ] CRUD operations on `payment_methods`

### Seller Withdraw Money
- [x] Create withdrawal request (insert into `withdrawal_requests`)
- [x] Fetch withdrawal history

### Seller Transactions
- [x] Fetch transaction history from `transactions`

### Seller Notifications
- [x] Fetch notifications from `notifications`

---

## 6. Chat / Messaging (Both Roles)

- [x] Fetch conversation list from `conversations` joined with `profiles`
- [x] Fetch messages for a conversation from `messages`
- [x] Send message (insert into `messages`)
- [x] Subscribe to Supabase Realtime for new messages
- [x] Mark messages as read
- [x] Support image/file attachments via Supabase Storage

---

## 7. App Architecture (Recommended Before Starting)

- [ ] Add state management (Provider, Riverpod, or Bloc)
- [ ] Create a service/repository layer for Supabase calls
- [ ] Create proper Dart model classes with `fromJson` / `toJson` for each table
- [ ] Set up named routing (GoRouter or auto_route) to replace direct `Navigator.push`
- [ ] Centralize error handling and loading states
- [ ] Remove all hardcoded mock data once real data is connected

---

## 8. Supabase Edge Functions (Optional / Later)

- [ ] Order completion logic (release payment to seller)
- [ ] Notification triggers (new order, new message, order delivered)
- [ ] Rating recalculation on new review
- [ ] Scheduled cleanup of expired/cancelled orders

---

## 9. Row Level Security (RLS) Policies

- [ ] Users can only read/update their own profile
- [ ] Services are publicly readable, only editable by the owning seller
- [ ] Orders are only visible to the involved client and seller
- [ ] Messages are only visible to conversation participants
- [ ] Favourites are private to the owning user
- [ ] Transactions are private to the owning user
- [ ] Job posts are publicly readable, only editable by the posting client

---

## Screen Count Summary

| Area | Screens | Status |
|------|---------|--------|
| Splash / Onboarding | 3 | UI done, needs purchase validation removal |
| Client Auth | 5 | UI done, needs Supabase auth |
| Client Home / Browse | 6 | UI done, needs real data |
| Client Orders | 2 | UI done, needs real data |
| Client Profile | 3 | UI done, needs real data |
| Client Job Posts | 3 | UI done, needs real data |
| Client Other (settings, notifications, etc.) | 10 | UI done, needs real data |
| Seller Auth | 4 | UI done, needs Supabase auth |
| Seller Home / Dashboard | 3 | UI done, needs real data |
| Seller Services | 3 | UI done, needs real data |
| Seller Orders | 4 | UI done, needs real data |
| Seller Profile | 3 | UI done, needs real data |
| Seller Other (chat, payments, settings, etc.) | 15+ | UI done, needs real data |
| **Total** | **~64 screens** | **All UI complete, 0% backend wired** |
