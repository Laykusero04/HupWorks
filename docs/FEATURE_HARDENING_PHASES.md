# Feature Hardening Plan

Focus set: incomplete onboarding / settings surfaces that look finished but do not work.  
Money (deposit / withdraw / payment methods) and OTP verification are **out of scope** for this plan.

| Priority | Feature | Why first |
|----------|---------|-----------|
| P0 | Create profile wizards | Blocks every new user; APIs already exist |
| P0 | Search | High-traffic home path; API already exists |
| P1 | About / Privacy | Fast content fix; builds trust |
| P1 | Report user | Needs schema; safety-critical |
| P2 | Invite / referral | Needs schema + product rules |
| P2 | Language / i18n | Greenfield; largest engineering cost |

---

## Current state (snapshot)

| Feature | Stub behavior | Reuse today | Schema gap |
|---------|---------------|-------------|------------|
| Create profile wizards | **Done** — persists via ProfileService | `ProfileService.updateProfile` / `updateSellerProfile` / `uploadProfileImage` | None |
| Search | **Done** — live services + detail nav | `ClientHomeService.searchServices(query)` | None |
| Invite / referral | **Done (MVP)** — per-user code + system share | `InviteService` / `share_plus` | Rewards schema deferred |
| Report user | **Done** — persists to `user_reports` | `ReportService.createReport` | Apply migration 0019 |
| Language | **Done (MVP)** — EN/BN via gen-l10n + prefs | `LocaleController` / `AppLocalizations` | More locales & string migration ongoing |
| About / Privacy | **Done** — shared HupWorks copy | `LegalCopy` / `LegalDocumentScreen` | Content-only |

---

## Phase 0 — Baseline (½ day)

Lock scope and avoid regressions while shipping.

- [x] Confirm product copy for About / Privacy (or draft interim HupWorks text)
- [x] Decide invite MVP: **share link only** vs **full referral rewards** → Option A (share-only)
- [x] Decide report MVP: **persist to Supabase** vs **forward to Tawk support chat** → Option A (persist)
- [x] Decide language MVP: **hide settings tile** until i18n, or ship **EN + one locale** → EN + Bengali
- [x] Note wizard vs OTP dependency: wizards are reached after stub OTP; this plan wires persist only — OTP remains separate

**Exit:** Decisions recorded for About/Privacy + Report; invite/language still open.

---

## Phase 1 — Create profile wizards (P0)

Wire onboarding Save to the same persistence path as edit profile.

### Files

| Role | Wizard | Working reference |
|------|--------|-------------------|
| Client | `lib/screen/client screen/client_authentication/client_create_profile.dart` | `client_edit_profile_details.dart` |
| Seller | `lib/screen/seller screen/setup seller profile/setup_profile.dart` | `seller_edit_profile_details.dart` |
| Shared popup | `SaveProfilePopUp` in seller popup | Should run **after** successful persist |

### Tasks

1. **Client wizard**
   - [x] Bind fields (name, phone, gender, location, bio as applicable)
   - [x] On Save: `ProfileService.updateProfile(...)`
   - [x] Optional avatar: `ProfileService.uploadProfileImage` (replace `ImportImagePopUp` no-op)
   - [x] Loading + error snackbar; success popup only after DB success
   - [x] Navigate to the correct post-onboarding destination (client home / login per existing auth flow)

2. **Seller wizard**
   - [x] Persist step data via `updateProfile` + `updateSellerProfile` (job title, about, skills, languages, education/address/DOB as UI collects)
   - [x] Reuse `SkillService.listForPicker` instead of hardcoded skills where possible
   - [x] Same loading / error / success-after-persist rules as client

3. **Cleanup**
   - [x] Stop relying on module-level `selectedGender` / `selectedLanguage` for wizard state (local state or controllers)
   - [x] Do **not** insert a new profile row — `handle_new_user` already creates `profiles` (+ seller row)

### Exit criteria

- New client/seller can complete wizard and see data on profile / edit screens
- Failed network shows an error; success popup never lies

**Estimate:** 1–2 days  
**Status:** Done (2026-07-29) — education/certification showcase removed (was fake); address/languages/skills/about persist.
---

## Phase 2 — Search (P0)

Replace fake delegate with real service search and navigation.

### Files

- `lib/screen/client screen/search/search.dart` — `CustomSearchDelegate`
- Wired from `client_home_screen.dart` via `showSearch`
- API: `ClientHomeService.searchServices(query)`
- Detail navigation: mirror home / talent / `ServiceDetailsService` patterns

### Tasks

1. [x] Call `searchServices` with debounce (empty query → suggestions or popular)
2. [x] Render service rows (title, seller, price/rating if returned)
3. [x] Tap → service details (and/or seller profile via existing public profile routes)
4. [x] Empty / error / loading states
5. [x] Optional stretch: search sellers by name, or category filter using `getCategories`

### Exit criteria

- Typing a real service title returns live rows
- Opening a result lands on a real detail screen

**Estimate:** 0.5–1 day  
**Status:** Done (2026-07-29) — services + freelancers sections; empty shows popular/top; seller tap → public profile.---

## Phase 3 — About / Privacy (P1)

Replace template leftovers with real product / legal copy.

### Files

| Screen | Path |
|--------|------|
| Client About | `lib/screen/client screen/client_setting/client_about.dart` |
| Client Policy | `lib/screen/client screen/client_setting/client_policy.dart` |
| Seller About | `lib/screen/seller screen/setting/seller_about.dart` |
| Seller Policy | `lib/screen/seller screen/setting/privacy_policy.dart` |

### Tasks

1. [x] Replace “Food First…” with HupWorks About + Privacy content (shared constants or markdown assets to avoid 4× drift)
2. [ ] Optional: open hosted legal URLs in WebView / external browser if counsel prefers live docs
3. [x] Keep client/seller screens in sync (shared widget or shared copy source)

### Exit criteria

- No third-party / food-sovereignty placeholder text in settings

**Estimate:** 0.5 day (content-dependent)  
**Status:** Done (2026-07-29) — `LegalCopy` + `LegalDocumentScreen`; interim HupWorks copy (replace with counsel text when ready).
---

## Phase 4 — Report user (P1)

Make Send actually record a report.

### Files

- `lib/screen/client screen/client report/client_report.dart`
- `lib/screen/seller screen/report/seller_report.dart`
- Reasons: `lib/core/constants/app_constants.dart` (`reportTitle` / `selectedReportTitle`)
- Also stubbed entry points: order details “Report”, chat inbox report menu (wire or hide)

### Option A — Persist (preferred for marketplace)

1. [x] Migration: `user_reports` (`reporter_id`, `reported_user_id`, `reason`, `details`, `profile_url?`, `status`, `created_at`) + RLS
2. [x] `ReportService.createReport(...)`
3. [x] Wire Cancel (pop) / Send (validate → insert → snackbar → pop)
4. [x] Replace global `selectedReportTitle` with local state
5. [x] Wire or remove order/chat report menus so they open this flow with `reported_user_id`

### Option B — Soft land

1. [ ] Prefill Tawk / support chat with reason + reported user id
2. [ ] Still require Cancel/Send to do something visible (no empty `onPressed`)

### Exit criteria

- Send creates a row (or opens support with context); Cancel dismisses
- Duplicate globals for report reason are gone from this flow

**Estimate:** 1–1.5 days (Option A)  
**Status:** Done (2026-07-29) — apply `migrations/0019_user_reports.sql` on Supabase before testing Send.
---

## Phase 5 — Invite / referral (P2)

### Files

- `lib/screen/client screen/client invite/client_invite.dart`
- `lib/screen/seller screen/setting/seller_invite.dart`
- Social icons: `lib/screen/widgets/icons.dart` (`SocialIcon` display-only today)

### Option A — Share-only MVP (no rewards)

1. [x] Generate or load a real invite code / deep link per user (e.g. profile id short code)
2. [x] Wire share buttons via `share_plus` (system sheet) — drop fake per-network icons or make them open the same share sheet
3. [x] Update copy so it does **not** promise €10 / 4 friends unless backend pays that

### Option B — Full referral

1. [ ] Schema: `referral_codes`, `referral_redemptions` (+ reward rules)
2. [ ] Apply code on signup / first login
3. [ ] Credit wallet / balance via trusted server RPC (not client-side balance writes)
4. [ ] Then wire UI to real code + share

### Exit criteria (MVP)

- User can copy and system-share a real code/link
- Marketing copy matches what the backend actually does

**Estimate:** 0.5 day (Option A) · 2–4 days (Option B)  
**Status:** Done (2026-07-29) — Option A; code `HW-XXXXXXXX` from user id; shared `InviteFriendsScreen`.
---

## Phase 6 — Language / i18n (P2)

Settings today only flip a local checkmark; the app has **no** `flutter_localizations`, ARB files, or locale persistence.

### Files

- `lib/screen/client screen/client_setting/client_language.dart`
- `lib/screen/seller screen/setting/language.dart`
- Note: wizard “language” fields are **spoken languages** on the profile (`seller_profiles.languages`), not app UI locale — keep those concepts separate

### Tasks

1. [x] Short term: hide Language tiles **or** show “English only” until i18n ships → shipped **EN + BN**
2. [x] Add Flutter gen-l10n (ARB), `MaterialApp.locale` / `localizationsDelegates`
3. [x] Persist preference (`shared_preferences` or `profiles.preferred_locale`)
4. [x] Wire settings radios to change locale and rebuild
5. [x] Migrate high-traffic strings first (settings, invite, search, report, about/privacy); rest incrementally

### Exit criteria

- Changing language updates visible UI strings and survives restart
- Profile spoken-language pickers remain independent of UI locale

**Estimate:** 3–5+ days (incremental)  
**Status:** Done (2026-07-29) — foundation + EN/NL/BN; default English. See `docs/APP_LANGUAGES.md`.
---

## Suggested delivery order

```text
Phase 0  Decisions
   │
Phase 1  Profile wizards ──────────────┐
Phase 2  Search                        ├── can run in parallel after Phase 0
Phase 3  About / Privacy ──────────────┘
   │
Phase 4  Report (schema + UI)
   │
Phase 5  Invite (share MVP → optional rewards)
   │
Phase 6  Language / i18n
```

**Rough total (MVP path):** ~4–6 days  
(wizards + search + about/privacy + report Option A + invite share-only; language deferred or hidden)

---

## Out of scope (track separately)

- Deposit / withdraw / add payment method
- OTP verification stubs
- ~~AuthBloc vs `AuthService` role mismatch~~ → **role routing fixed** (`profiles.role` + `RoleCache`)
- Push notifications (FCM)
- ~~Empty `catch (_) {}` sweep across homes/orders~~ → **logged via `AppLogger`** (+ snackbar where user-visible)
- ~~AuthBloc unused~~ → removed from `app.dart`; bloc/repo files parked

---

## Progress log

| Phase | Status | Notes |
|-------|--------|-------|
| 0 Baseline | Done | About/report/invite/language decisions locked |
| 1 Profile wizards | Done | Persist via ProfileService; avatar upload; home after success |
| 2 Search | Done | Services + freelancers; popular/top when empty |
| 3 About / Privacy | Done | Shared `LegalCopy` (interim HupWorks text) |
| 4 Report user | Done | `user_reports` + ReportService; chat/order menus wired |
| 5 Invite / referral | Done | Share-only MVP; no fake €10 rewards |
| 6 Language / i18n | Done | EN+BN gen-l10n; prefs persist; settings wired |
