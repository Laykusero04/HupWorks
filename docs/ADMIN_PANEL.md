# HupWorks Admin Panel — Ideal Actions & Insights

**Status:** React admin shell lives in [`website/`](../website/) (Vite + React Router). Queues are still placeholders — sellers already submit identity selfies for “admin review later,” and users file reports into Supabase.

This document is the product + technical blueprint for that **web admin**, backed by the same Supabase project as the Flutter app.

---

## 1. Goal

Give operators a safe control surface to:

1. **Approve trust** — seller identity verification (the main trust gate in the app)
2. **Keep the marketplace safe** — moderate user reports and abusive accounts/jobs
3. **Unstick operations** — contracts, cancellations, unpaid completed work (payments are off-app)
4. **Steer growth** — funnels, supply/demand, and health metrics

Money rails (deposit / withdraw / PSP) are **out of scope** for the mobile app today. Admin should still surface **off-app payment confirmation** and dispute reports — not settle card charges.

---

## 2. Supabase connection (website / admin backend)

Use the **same** Supabase project as the Flutter client. Keys live in local `.env` (never commit secrets).

| Variable | Used by | Purpose |
|----------|---------|---------|
| `SUPABASE_URL` | Flutter app + admin website | Project API URL |
| `SUPABASE_ANON_KEY` | Flutter app only | Public client key (RLS applies) |
| `SUPABASE_SECRET_KEY` | **Admin backend / server only** | Service role — bypasses RLS for review queues |
| `TAWK_DIRECT_CHAT_LINK` | Flutter Help & Support | Optional: link support tickets to Tawk |

### Rules

- The **Flutter app must never** embed `SUPABASE_SECRET_KEY`.
- The **admin website** should call Supabase either:
  - from a **server** (Next.js API routes, Edge Functions, etc.) using the secret key, or
  - via dedicated **admin RPCs** after you add an `admin` role + RLS.
- Prefer short-lived **signed URLs** for identity selfies in bucket `identity-docs` (private).
- Document redirect URLs separately for auth; admin login should be staff-only (separate allowlist or `app_metadata.role = admin`).

### Example `.env` for admin website (names only)

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key          # optional if UI uses user session
SUPABASE_SECRET_KEY=your-service-role-key  # server-side only
```

Copy from the root `.env` / `.env.example` used by the mobile project so URL and project stay aligned.

---

## 3. Current product facts (what admin must respect)

| Area | Reality |
|------|---------|
| Roles today | `profiles.role`: `client` \| `seller` only — **no admin role in DB** |
| Trust score | Sellers earn **100** only after verification status is `verified` |
| Payments | Confirmed manually via `orders.payment_received_at` — cash/bank/e-wallet outside the app |
| Disputes | No `disputes` table — use `user_reports` (+ chat context) |
| Identity storage | Private bucket `identity-docs/{userId}/id_selfie.jpg` |
| Access today | Supabase Dashboard + service role until admin UI ships |

---

## 4. Priority modules (ideal admin actions)

Build in this order — highest ROI first.

### P0 — Identity verification queue

**Why:** Onboarding copy and trust badges already promise admin review. Pending sellers are blocked from full trust.

| Action | Data | Notes |
|--------|------|-------|
| List pending submissions | `seller_identity_verifications` where `status = 'pending'` | Sort by `submitted_at` ascending (oldest first) |
| Preview selfie | Storage path `id_selfie_path` → signed URL | Never make bucket public |
| Approve face+ID | Set identity `status = 'verified'` (+ sync `profiles.verification_status`) | +50 trust |
| Reject face+ID | Set identity `rejected` + reason | Seller can resubmit selfie |
| Approve profile photo | Set `profiles.profile_photo_status = 'verified'` | +50 trust |
| Reject profile photo | Set `profile_photo_status = 'rejected'` + reason | Seller can replace photo |

**Status fields:**

| Track | Fields |
|-------|--------|
| Face + ID | `seller_identity_verifications` + `profiles.verification_status` ∈ `unverified` \| `pending` \| `verified` \| `rejected` |
| Profile photo | `profiles.profile_photo_status` (+ `profile_photo_reviewed_at`, `profile_photo_rejection_reason`) |

Fully verified badge / 100 score requires **both** tracks accepted.

**Hardening (before launch):** stop sellers from self-updating `status` to `verified` via RLS; restrict status changes to admin/service role.

---

### P0 — Report / safety moderation

**Why:** Only formal abuse channel in the app.

| Action | Data |
|--------|------|
| Inbox | `user_reports` where `status` in (`open`, `reviewing`) |
| Triage | Set `status` → `reviewing` → `resolved` or `dismissed` |
| Open context | Join `reporter_id`, `reported_user_id`, optional `job_post_id`, `order_id` |
| Soft block | `user_blocks` between the pair (directional); admin card shows `pair_blocked` |
| Escalate | Soft-disable user, close fake job posts, note payment disputes |

**Report reasons (app codes):** harassment, fake job, no-show, payment dispute, spam, trademark, copyright, non-original, other.

**Statuses:** `open` → `reviewing` → `resolved` \| `dismissed`.

#### Fair soft-block rules (PoC)

Blocking is **directional** (`blocker_id` → `blocked_id`) but contact hide is **mutual**.

**Open obligation** (protected — both parties keep order/payment/dispute access):

- order `status` in `pending` \| `active` \| `delivered` \| `cancellation_requested`, **or**
- `completed` with `payment_received_at` null

While protected: chat send may continue; hire/new DMs stay allowed for that pair until the obligation clears. Soft block never cancels orders or clears payment flags.

After obligation clears: composer disabled; Message/Hire CTAs refuse with contact-blocked.

**Apply SQL:** run [`migrations/0039_user_blocks.sql`](../migrations/0039_user_blocks.sql) in the Supabase SQL Editor (idempotent; also creates `user_reports` if missing). Optional helper: `node tools/apply_report_block_sql.mjs` with `SUPABASE_ACCESS_TOKEN` or `DATABASE_URL`.

#### PoC demo script

1. Apply `0039_user_blocks.sql` (fixes Admin Reports schema-cache error).
2. Client + seller complete a job → leave `payment_received_at` null.
3. Client taps **Block** in chat → sees open-obligation warning → soft block; optional payment-dispute report.
4. Seller can still open the order, mark payment, or file a payment dispute.
5. After payment is marked (or order cancelled) → chat composer shows contact blocked; Message/Hire refuse.
6. Reverse roles (seller blocks unpaid client) → same protections.

---

### P1 — Users & sellers

| Action | Why |
|--------|-----|
| Search by email / name / id | Support lookups |
| See role, city, rating, verification, `seller_onboarding_completed` | Funnel + trust |
| View seller public vs private details | DOB / address for compliance review (private table) |
| Soft-disable / flag account | Abuse response (needs schema if not present yet) |
| Incomplete onboarding list | Sellers with `seller_onboarding_completed = false` |

---

### P1 — Jobs & contracts (ops)

Happy path: job open → offer → hire → order `active` → `delivered` → `completed` → optional payment mark.

| Queue / action | When it matters |
|----------------|-----------------|
| Stuck `cancellation_requested` | Client silent before 48h auto-expire — mediate or force-cancel via service role |
| Long `delivered` without complete | Client not closing — nudge / investigate |
| `completed` with `payment_received_at` null | Off-app unpaid risk — primary money insight |
| Declined `hour_reports` + payment report | Wage / hours dispute |
| Close misleading `job_posts` | Fake-job reports |

Order statuses: `pending` \| `active` \| `delivered` \| `completed` \| `cancelled` \| `cancellation_requested`.

---

### P2 — Catalog & content

| Action | Tables |
|--------|--------|
| Translate category names/descriptions (`en` / `nl` / `bn`) | `categories.name_i18n`, `categories.description_i18n` via admin **Catalog** |
| Activate / seed skills | `skill_catalog` |
| Moderate custom categories | `categories` / related custom category flow |
| Legacy services visibility | `services` (`active` \| `paused`) if still exposed |

Category i18n: keep English `name` as the canonical unique key. App locale picks from jsonb maps; missing locales fall back to English. Apply `migrations/0040_category_i18n.sql` before using Catalog translations.

---

### P3 — Later (when money features ship)

Schema already has `transactions`, `payment_methods`, `withdrawal_requests` — **unused in Flutter today**.

When enabled: approve/reject withdrawals, investigate failed deposits, reconcile balances. Until then, keep out of the primary admin nav.

---

## 5. Insights dashboard (high-value metrics)

Group widgets so operators see **health**, not vanity charts.

### Growth & funnel

| Insight | How to derive |
|---------|----------------|
| New clients vs sellers (7/30d) | `profiles` by `role` + `created_at` |
| Seller onboarding completion rate | `seller_onboarding_completed` true / sellers created |
| Verification funnel | counts by `verification_status`; median time `submitted_at` → `reviewed_at` |
| Pending review SLA | age of oldest pending selfie |

### Marketplace health

| Insight | How to derive |
|---------|----------------|
| Open jobs / offers pending | `job_posts.status`, `job_offers.status` |
| Offer accept rate | accepted / total offers |
| Active contracts | orders in `active` \| `delivered` \| `cancellation_requested` |
| Completion rate | completed / (completed + cancelled) |
| Cancellation reasons mix | cancellation reason fields on orders |
| Time-to-complete | hire → completed distribution |

### Money (off-app)

| Insight | How to derive |
|---------|----------------|
| Completed GMV | `sum(price)` where `orders.status = 'completed'` |
| Paid vs unpaid completed | `payment_received_at` IS NULL vs NOT NULL |
| Accepted hours volume | `hour_reports` where status accepted → sum `minutes` |

### Trust & safety

| Insight | How to derive |
|---------|----------------|
| Open report volume by reason | `user_reports` group by `reason`, `status` |
| Verified seller % | sellers with `verification_status = verified` |
| Repeat reported users | count reports per `reported_user_id` |
| Onsite trust activity | attendance punches / completed onsite jobs (existing trust RPC) |

### Suggested home KPI strip

1. Pending identity reviews  
2. Open reports  
3. Unpaid completed orders  
4. Active contracts  
5. Median verification review time (hours)

---

## 6. Suggested admin IA (website)

```
Admin
├── Overview (KPIs + alerts)
├── Verification (pending / verified / rejected)
├── Reports (inbox + detail)
├── Users (clients & sellers)
├── Jobs & orders (search + stuck queues)
├── Catalog (skills / categories)
└── Settings (staff accounts, audit log)   [later]
```

---

## 7. Recommended backend shape

### Near-term (ship fast)

1. Staff web app + **server routes** using `SUPABASE_SECRET_KEY`
2. Pages for Verification + Reports first
3. Audit log table (who approved/rejected what) — strongly recommended even for MVP

### Medium-term (secure properly)

1. Add `profiles.role = 'admin'` **or** `auth.users.raw_app_meta_data.role = 'admin'`
2. RLS policies: admins can select/update verification + reports + storage read on `identity-docs`
3. Lock seller policies so they cannot set `status = verified` themselves
4. Admin RPCs: `admin_review_identity(user_id, decision, reason)`, `admin_set_report_status(...)`

### Do not

- Put the service role in the Flutter binary or a public SPA without a backend
- Expose raw identity images without auth + short TTL signed URLs
- Treat `payment_received_*` as bank truth — it is a mutual ledger flag only

---

## 8. Alert rules (nice-to-have)

| Alert | Condition |
|-------|-----------|
| Verification backlog | Pending count > N or oldest > 24–48h |
| Safety spike | Open reports in 24h > threshold |
| Unpaid completed | Completed + unpaid > 7 days |
| Stuck cancellation | `cancellation_requested` > 24h without client action |

Notify via email, Slack, or Tawk ops channel.

---

## 9. Implementation checklist

- [ ] Scaffold admin website against same `SUPABASE_URL` → [`website/`](../website/) (Vite + React shell)
- [ ] Identity queue: list / signed preview / approve / reject
- [ ] Reports queue: status workflow + job/order deep links
- [ ] Overview KPIs (section 5 strip)
- [ ] Harden RLS (admin-only status changes)
- [ ] Audit log for admin writes
- [ ] Users + stuck orders queues
- [x] Catalog category translations (en / nl / bn)
- [ ] (Later) withdrawals if money features launch

---

## 10. Related migrations & code

| Topic | Reference |
|-------|-----------|
| Identity verification | `migrations/0034_seller_identity_verification.sql` |
| Seller onboarding flag | `migrations/0035_seller_onboarding_completed.sql` |
| Signup profile trigger | `migrations/0036_fix_signup_profile_trigger.sql` |
| Off-app payment mark | `migrations/0037_order_payment_received.sql` |
| User reports | `migrations/0019_user_reports.sql`, `0023_user_reports_job_context.sql` |
| Soft blocks | `migrations/0039_user_blocks.sql`, `lib/services/block_service.dart` |
| Seller submit UI | `lib/services/verification_service.dart`, setup profile / identity screens |
| App env loading | `lib/main.dart` (`SUPABASE_URL`, `SUPABASE_ANON_KEY` only) |

---

## Summary

**Build admin for trust and safety first** (identity + reports), then **ops visibility** (unpaid completed, stuck cancellations), then catalog. Connect the website to the shared Supabase project; keep the **secret key server-side**. Insights should emphasize funnel completion, verification SLA, report volume, and unpaid completed GMV — those match how HupWorks actually runs money and trust today.
