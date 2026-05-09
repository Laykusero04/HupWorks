# HupWorks Flow Migration: Service Marketplace → Job Marketplace

**Status:** Design — not yet implemented.
**Owner:** TBD
**Last updated:** 2026-05-09

## 1. Goal

Pivot HupWorks from a **Fiverr-style** marketplace (sellers list services, clients buy them) to an **Upwork-style** marketplace (clients post jobs, freelancers apply).

For this iteration, jobs are categorized by **engagement type**: `gig`, `full_time`, `part_time`.

## 2. Current vs Target Model

| Concept | Current (Fiverr-style) | Target (Upwork-style) |
|---|---|---|
| Who creates the listing? | Seller creates a Service | Client creates a Job |
| What does the other side do? | Client buys a Service → Order | Freelancer applies to a Job → Application |
| What is on a listing? | Title, price, delivery time, images | Title, description, budget range, deadline, **job type** |
| How does work begin? | Client places order on a fixed service | Client accepts an application → contract |
| Browsing surface | Popular Services, Top Sellers, Categories | Open Jobs, Categories, **filter by job type** |

## 3. The good news

[seller_buyer_request.dart](lib/screen/seller%20screen/buyer%20request/seller_buyer_request.dart) and [create_customer_offer.dart](lib/screen/seller%20screen/buyer%20request/create_customer_offer.dart) already implement ~60% of the freelancer-application flow. Sellers already browse open `job_posts` and submit `job_offers` rows containing `price`, `delivery_time`, and `cover_letter`. We are **renaming and surfacing** this feature, not building it from scratch.

The client-side [client_job_post.dart](lib/screen/client%20screen/client%20job%20post/client_job_post.dart) and [create_new_job_post.dart](lib/screen/client%20screen/client%20job%20post/create_new_job_post.dart) are already production-shaped. We add a `job_type` field and that's most of it.

## 4. Inventory: Remove / Repurpose / Add

### 4.1 Remove (from app surface; defer DB cleanup)

| Item | Files | Action |
|---|---|---|
| Seller "Create Service" tab | [create_service.dart](lib/screen/seller%20screen/seller%20services/create_service.dart), [create_new_service.dart](lib/screen/seller%20screen/seller%20services/create_new_service.dart) | Remove from bottom nav. Keep files until DB migration completes. |
| Seller "My Services" home section | [seller_home_screen.dart](lib/screen/seller%20screen/seller%20home/seller_home_screen.dart), [my_service.dart](lib/screen/seller%20screen/seller%20home/my%20service/my_service.dart), [service_details.dart](lib/screen/seller%20screen/seller%20home/my%20service/service_details.dart) | Remove the section from the home; replace with "My Applications". |
| Client "Popular Services" / "Top Sellers" home sections | [client_home_screen.dart](lib/screen/client%20screen/client%20home/client_home_screen.dart#L298-L565), [popular_services.dart](lib/screen/client%20screen/client%20home/popular_services.dart), [top_seller.dart](lib/screen/client%20screen/client%20home/top_seller.dart) | Remove. Replace with "Recent Open Jobs" + "Top Freelancers". |
| Client "Service Details / Place Order" | [client_service_details.dart](lib/screen/client%20screen/client%20service%20details/client_service_details.dart), [requirements.dart](lib/screen/client%20screen/client%20service%20details/requirements.dart), [client_order.dart](lib/screen/client%20screen/client%20service%20details/client_order.dart) | Remove navigation to these. Keep files for reference until orders schema is migrated. |
| Service-level favourites | [seller_favourite_list.dart](lib/screen/seller%20screen/favourite/seller_favourite_list.dart), [client_favourite_list.dart](lib/screen/client%20screen/client%20favourite/client_favourite_list.dart) | Repurpose to favourite **jobs** (client-side: jobs they bookmarked; seller-side: jobs to apply to later). |

### 4.2 Repurpose

| Existing | Becomes | Why |
|---|---|---|
| `seller buyer request` screens | "Find Jobs" tab — primary seller surface | Already lists open `job_posts`. |
| `create_customer_offer.dart` | "Submit Application" screen | Already writes to `job_offers`. Rename UI labels (`cover_letter` → "Proposal", `delivery_time` → "Estimated duration"). |
| `JobPostsService.getJobOffers()` | "Applications received" view (client side) | Already exists. |
| `orders` table | `contracts` (link to `job_offers.id`, not `services.id`) | Track work that started after an application was accepted. |
| `reviews` (currently `service_id`) | `reviews` linked to `contracts.id` instead | Reviews follow a finished contract, not a service. |
| Seller bottom nav "Service" tab | "Find Jobs" tab | Reuse the slot; route `/seller/find-jobs`. |

### 4.3 Add

| New | Where |
|---|---|
| `job_type` field on `job_posts` (`gig` / `full_time` / `part_time`) | DB migration; UI on create/edit; filter on browse. |
| Seller "My Applications" screen | `/seller/applications` — list of their submitted `job_offers` with status. |
| Client "Applications received" screen on a job detail | Extend [job_details.dart](lib/screen/client%20screen/client%20job%20post/job_details.dart) — list `job_offers`, accept/reject. |
| Application status state machine | `pending → accepted → contract_started` or `pending → rejected`. |

## 5. Database changes

```sql
-- 5.1  Add job_type to job_posts
ALTER TABLE job_posts
  ADD COLUMN job_type TEXT NOT NULL DEFAULT 'gig'
    CHECK (job_type IN ('gig', 'full_time', 'part_time'));

-- 5.2  job_offers becomes the application of record (rename optional)
-- Existing columns stay: id, job_post_id, seller_id, price, delivery_time, cover_letter, status
-- Status values: 'pending' | 'accepted' | 'rejected' | 'withdrawn'

-- 5.3  Link orders -> job_offers instead of services (over time)
ALTER TABLE orders
  ADD COLUMN job_offer_id UUID REFERENCES job_offers(id);
-- Keep service_id nullable while old rows exist; drop later.

-- 5.4  Reviews follow the contract, not the service
ALTER TABLE reviews
  ADD COLUMN job_offer_id UUID REFERENCES job_offers(id);
```

**Don't drop `services` / `service_requirements` yet.** Keep them while orders migrates over. Drop in a follow-up after the new flow is stable in production for one release cycle.

## 6. Routing & navigation changes

[app_router.dart](lib/router/app_router.dart)

### Client bottom nav (no structural change)

| Index | Old | New | Notes |
|---|---|---|---|
| 0 | Home | Home | Replace service sections with job sections |
| 1 | Message | Message | Unchanged |
| 2 | Job Apply | **My Jobs** | Better label — these are jobs the client posted |
| 3 | Orders | **Contracts** | Renamed; backed by `orders` linked to accepted offers |
| 4 | Profile | Profile | Unchanged |

### Seller bottom nav (one tab swap)

| Index | Old | New | Notes |
|---|---|---|---|
| 0 | Home | Home | Replace "My Services" with "My Applications" |
| 1 | Message | Message | Unchanged |
| 2 | **Service** (`/seller/create-service`) | **Find Jobs** (`/seller/find-jobs`) | Replace branch entirely |
| 3 | Orders | **Contracts** | Same renaming as client side |
| 4 | Profile | Profile | Unchanged |

## 7. Screen-by-screen plan

### 7.1 Client side

- **[create_new_job_post.dart](lib/screen/client%20screen/client%20job%20post/create_new_job_post.dart)** — Add a `DropdownButtonFormField<String>` for `job_type` with values `gig` / `full_time` / `part_time`. Persist via `JobPostsService.createJobPost`.
- **[client_job_post.dart](lib/screen/client%20screen/client%20job%20post/client_job_post.dart)** — Add a chip-row filter at the top for job type. Show `job_type` as a badge on each card.
- **[job_details.dart](lib/screen/client%20screen/client%20job%20post/job_details.dart)** — Add an "Applications" section listing `job_offers` for this post with Accept / Reject actions. Accepting creates a row in `orders` with `job_offer_id` and sets `job_offers.status = 'accepted'`.
- **[client_home_screen.dart](lib/screen/client%20screen/client%20home/client_home_screen.dart)** — Replace "Popular Services" / "Top Sellers" sections with "My Recent Jobs" + "Suggested Freelancers" (top-rated profiles with `role='seller'`).

### 7.2 Seller (freelancer) side

- **`/seller/find-jobs`** — Promote [seller_buyer_request.dart](lib/screen/seller%20screen/buyer%20request/seller_buyer_request.dart) to a top-level tab. Add filters for category and `job_type`.
- **[create_customer_offer.dart](lib/screen/seller%20screen/buyer%20request/create_customer_offer.dart)** — Rename UI labels: "Create Offer" → "Submit Application"; `cover_letter` field → "Proposal".
- **New `/seller/applications`** — List the freelancer's own `job_offers` rows with status badges. Pulls from a new method `getMyApplications()` on `SellerOrdersService` (filter by `seller_id = current user`).
- **[seller_home_screen.dart](lib/screen/seller%20screen/seller%20home/seller_home_screen.dart)** — Replace "My Services" section with "My Applications" + "Recommended Jobs".
- **Delete from nav (not yet from disk):** "Create Service" and "My Services" entry points.

### 7.3 Auth / signup

- **No change in this iteration.** `role='seller'` semantically becomes "freelancer" but we keep the value to avoid migration. UI copy can read "Freelancer" while the DB value stays `seller`.

## 8. Phased rollout

Order matters because we don't want to ship a half-broken UI.

**Phase 1 — Schema (1 migration, no UI change)** — ✅ Done. See [migrations/0001_phase1_job_type_and_job_offer_links.sql](migrations/0001_phase1_job_type_and_job_offer_links.sql).
- Add `job_type` to `job_posts`. ✅
- Add `job_offer_id` to `orders` and `reviews`. ✅
- Backfill `job_type = 'gig'` for existing rows. ✅ (Handled automatically by `NOT NULL DEFAULT 'gig'`.)

**Phase 2 — Client posting + browsing** — ✅ Done.
- Add `job_type` selector to create-job form. ✅ ChoiceChip row in [create_new_job_post.dart](lib/screen/client%20screen/client%20job%20post/create_new_job_post.dart).
- Show `job_type` badge and filter on the job list. ✅ Filter chips + per-card badge in [client_job_post.dart](lib/screen/client%20screen/client%20job%20post/client_job_post.dart). `JobPostsService.createJobPost` now accepts `jobType` (default `'gig'`).

**Phase 3 — Freelancer apply flow surfaced** — ✅ Done.
- Promote "Buyer Requests" to "Find Jobs" (rename, replace seller bottom-nav slot 2). ✅ `/seller/find-jobs` is now slot 2 with `IconlyBold.search`. AppBar title flipped to "Find Jobs".
- Rename "Create Offer" → "Submit Application"; relabel `cover_letter` → "Proposal". ✅ Plus button "Send Offer" → "Apply Now", "Total Offer Amount" → "Your Bid", "Offer sent successfully!" → "Application submitted!".
- Add `/seller/applications` screen. ✅ New screen at [seller_applications.dart](lib/screen/seller%20screen/applications/seller_applications.dart) backed by `SellerOrdersService.getMyApplications()`. Surfaced via the seller profile menu (replaces the now-redundant "Buyer Requests" entry).

**Phase 4 — Client review/accept** — ✅ Done. Requires running [migrations/0002_phase4_accept_offer.sql](migrations/0002_phase4_accept_offer.sql).
- Applications section on `job_details.dart` with accept/reject. ✅ Renamed "Seller Offers" → "Applications", "Accept" button → "Hire", confirmation dialog before hiring.
- Accept action: insert into `orders` with `job_offer_id`, set offer status `accepted`. ✅ Done atomically server-side via the `accept_job_offer(uuid)` RPC, which also auto-rejects sibling pending offers and closes the parent job post.

Side-effect of Phase 4: `orders.service_id` is now nullable (contracts created from job offers have no associated service).

**Phase 5 — Home screens & contracts rename** — ✅ Done.
- Replace client home "Popular Services" / "Top Sellers" with job-centric content. ✅ Popular Services → "My Recent Jobs" (top 3 from `getClientJobPosts`, with type/status badges); "Top Sellers" header → "Suggested Freelancers" (same data); the entire "Recent Viewed" services section was removed.
- Replace seller home "My Services" with "My Applications". ✅ Bottom section now lists the freelancer's recent 5 `job_offers` (job title, status pill, bid + delivery), with "View All" → `SellerApplications`.
- Rename "Orders" tab to "Contracts" on both shells. ✅ Bottom-nav labels and AppBar titles updated on [client_orders.dart](lib/screen/client%20screen/client%20orders/client_orders.dart) and [seller_orders.dart](lib/screen/seller%20screen/orders/seller_orders.dart). Client tab "Job Apply" also relabeled to "My Jobs".

**Phase 6 — Cleanup** — ✅ Done (frontend); DB drop is deferred.
- Remove `create_service.dart`, `create_new_service.dart`, `my_service.dart`, `service_details.dart` and their imports. ✅ Plus the legacy `client_home.dart` / `seller_home.dart`, the entire `lib/features/{client,seller,shared}/` dead-bloc tree (zero consumers), and the unused `ServiceRepository` / `RecentlyViewedRepository` / `seller_service_management.dart`.
- Remove client service-detail/order/requirements screens. ✅ `client_order.dart`, `client_add_card.dart`, `requirements.dart`, `popular_services.dart`, `recently_view.dart` all gone. (`client_service_details.dart` and the favorites screens are kept — they're reachable from the profile menu and form the basis for the "favourite jobs" repurpose noted in §4.1.)
- Drop `services` / `service_requirements` tables once no orders reference them. ⏸ Deferred — see [migrations/0003_phase6_drop_services_DEFERRED.sql](migrations/0003_phase6_drop_services_DEFERRED.sql) for the script and a pre-flight check.

## 9. Open questions

1. **Job-type semantics.** Should `gig` allow a budget range while `full_time` / `part_time` use a monthly/hourly rate? For Phase 1 we keep one schema (budget min/max) and treat all three the same; revisit later.
2. **Reviews for in-progress contracts.** Today reviews link to `service_id`. Should we allow mid-contract reviews or only on completion?
3. **What happens to existing orders?** Backfill them with synthetic `job_offer_id`s? Leave `service_id` populated for legacy reads? Decision affects migration complexity.
4. **Naming of `job_offers`.** The table works as-is, but `applications` reads cleaner. Renaming costs one migration + a code-wide find/replace. Worth doing in Phase 6 if we're already cleaning up.
5. **Role label.** Show "Freelancer" in UI while DB keeps `seller`? Or do a one-time migration to rename the role value? Recommend the former — UI-only rename is reversible.

## 10. Out of scope (this doc)

- Payments / escrow flow.
- Hourly time-tracking for `full_time` / `part_time` engagements.
- Disputes & refunds.
- Featured / promoted jobs.

These are next-iteration decisions and don't block the pivot.
