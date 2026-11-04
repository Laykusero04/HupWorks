# Feature UI/UX adjustments

Small, concrete improvements based on the current HupWorks implementation. Each item is one change per feature: what the screen does today, the gap in the code, and how to adjust it.

The highest-value changes are mismatches between what a screen shows and what the code does. A failed load often looks like an empty account, and several primary buttons look tappable while the handler does nothing or writes the wrong data.

How to use this file:

1. Finish one phase before starting the next. The order is below.
2. Inside a phase, copy each **Prompt** in the listed order, one prompt per chat.
3. Tick that feature’s checklist only after the behavior in the prompt is true in the app.
4. Tick the phase when every feature in it is done.

## Phasing

Do the phases in order. Phase 1 changes what gets saved. Later phases change what the screen says after a tap or a failed load. Mixing them in one chat makes it easy to undo a data fix while polishing copy.

| Phase | Goal | Prompts | Stop when |
|-------|------|---------|-----------|
| 1 | Stop writing the wrong data | 4 | Profile save keeps city and country, a bad budget cannot post, a double tap cannot create two service orders, and review screens no longer offer a photo |
| 2 | Make primary actions honest | 8 | Close, hire, message, cancel, undo payment, clock-out, and remove-favourite either confirm or do the action their label describes |
| 3 | Show failure instead of an empty account | 11 | A failed load shows Retry. An empty filter does not offer Post a job, Browse jobs, or Create alert |
| 4 | Unblock entry and the seller shell | 4 | Language is a real first step, login and reset return to the right screen, and seller pages pushed off the tab shell stay blue |
| 5 | Shared polish | 4 | Chat, notifications, search, the map pin, the category field, and report errors match the rest of the app |

### Phase 1 — Protect stored data

Copy these prompts in this order.

- [x] [Edit profile](#edit-profile)
- [x] [Post a job](#post-a-job)
- [x] [Buy a service](#buy-a-service)
- [x] [Reviews](#reviews)

**Exit.** Saving a seller profile does not clear city or country. Posting a job rejects a reversed or unparsable budget. Ordering a service ignores a second tap and confirms price first. Both review screens publish only rating and comment.

### Phase 2 — Honest actions

Copy these prompts in this order. Hire comes before the contract screens because it creates the contract those screens open.

- [x] [Job details](#job-details)
- [x] [Hire from the inbox](#hire-from-the-inbox)
- [x] [Contract details](#contract-details)
- [x] [Contract details and delivery](#contract-details-and-delivery)
- [x] [Off-app payment](#off-app-payment)
- [x] [Cancellation and delivery files](#cancellation-and-delivery-files)
- [x] [Favourites](#favourites)
- [x] [Attendance](#attendance)

**Exit.** A failed job or seller contract load cannot close, cancel, or deliver. Inbox hire opens the same instructions sheet as job details and passes the site. Client open contracts message the freelancer. Payment undo, cancellation submit, favourite remove, and self-report clock-out confirm before they change data. Delivery files open.

### Phase 3 — Failure versus empty

Copy these prompts in this order. Splash is first because a stuck role blocks every later test. Verification is next because a failed load currently invites a new submission.

- [x] [Splash](#splash)
- [x] [Employer verification](#employer-verification)
- [x] [Identity verification](#identity-verification)
- [x] [Seller home](#seller-home)
- [x] [Contracts](#contracts)
- [x] [Find jobs and job details](#find-jobs-and-job-details)
- [x] [My applications](#my-applications)
- [x] [Job alerts](#job-alerts)
- [x] [Categories](#categories)
- [x] [My jobs](#my-jobs)
- [x] [Applications inbox](#applications-inbox)

**Exit.** Each of these screens has a Retry state for a thrown request, and a successful empty or filtered-empty list keeps its current action (post, browse, create, or clear filter). Splash stops retrying and offers Sign out.

### Phase 4 — Entry and shell

Copy these prompts in this order.

- [x] [Onboarding](#onboarding)
- [x] [Login and password reset](#login-and-password-reset)
- [x] [Email confirmation](#email-confirmation)
- [x] [Seller screens outside the shell](#seller-screens-outside-the-shell)

**Exit.** Language is an explicit first step, keyboard Done logs in, the reset snackbar survives the pop, Resend has a cooldown, Back does not stack another login, and seller routes outside the tab shell use the seller theme.

### Phase 5 — Shared polish

Copy these prompts in this order.

- [x] [Chat](#chat)
- [x] [Notifications](#notifications)
- [x] [Search, categories, and the map pin](#search-categories-and-the-map-pin)
- [x] [Report a user](#report-a-user)

**Exit.** Attach can use the camera, unread state shows on every shell tab, search and map errors are localized, Add category stays available when search matches nothing, and a short report note shows an error on the field.

## Shared entry and shell

- [x] Splash — Phase 3
- [x] Onboarding — Phase 4
- [x] Login and password reset — Phase 4
- [x] Email confirmation — Phase 4
- [x] Seller screens outside the shell — Phase 4

### Splash

**Phase 3.** Do this first inside Phase 3, before the failed-load screens.

`SplashScreen` (`lib/screen/splash screen/mt_splash_screen.dart`) waits for the Rubik animation and `AuthService.cachedRole`, then routes to onboarding, welcome, or the role home. If the user has a session but the role never arrives, `_goNext` reschedules itself every 350 ms with no cap.

```dart
final role = AuthService.cachedRole;
if (role == null) {
  _navigating = false;
  Future<void>.delayed(const Duration(milliseconds: 350), () {
    if (mounted) _goNext();
  });
  return;
}
```

The status line is also hardcoded English (`Getting things ready…`).

**Adjustment.** After about eight retries, stop the loop and show a localized failure state with Retry and Sign out. Retry calls the same role warm-up. Sign out clears the session and goes to `/welcome`. Move the status and version strings into the existing English and Dutch ARB files.

**Checklist**

- [x] `_goNext` stops after about 8 retries when `cachedRole` stays null.
- [x] The failure state shows Retry and Sign out.
- [x] Retry runs the same role warm-up and can navigate once the role arrives.
- [x] Sign out clears the session and goes to `/welcome`.
- [x] A successful role load still goes to the role home. A logged-out user still goes to `/onboard` or `/welcome`.
- [x] Status and version copy come from `app_en.arb` and `app_nl.arb`.

**Prompt**

```text
Implement the Splash section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/splash screen/mt_splash_screen.dart and the English and Dutch ARB files.
Cap the null-role retry loop at about 8 attempts. Then show a localized failure state with Retry and Sign out.
Retry re-runs the existing role warm-up. Sign out clears the session and goes to /welcome.
Keep the current navigation when the role loads or when there is no session.
Replace the hardcoded splash status and version strings with l10n keys.
```

### Onboarding

**Phase 4.** First prompt in Phase 4.

`OnBoard` (`lib/screen/splash screen/onboard.dart`) is a 10-page `PageView`: language, then nine platform-rule steps. Skip calls `_finish()` on every page, including the language page. Ten 6 px dots do not communicate “step 4 of 10,” and pages 4–9 reuse the same three images.

**Adjustment.** On page 0, replace Skip with Continue so the language choice is explicit (`_LanguageOptionTile` already writes the locale). From page 1 on, keep Skip. Under the button, show a text counter such as `2 / 10` instead of the dot row.

**Checklist**

- [x] Page 0 shows Continue and does not call `_finish()`.
- [x] Pages 1–9 still show Skip, and Skip still marks onboarding seen and goes to `/welcome`.
- [x] A text counter such as `2 / 10` replaces the 10-dot indicator.
- [x] Language selection still writes the locale through `_LanguageOptionTile`.

**Prompt**

```text
Implement the Onboarding section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/splash screen/onboard.dart and ARB files if a new counter string is needed.
On page 0, replace Skip with Continue so the user advances to the rules without finishing onboarding.
From page 1 onward, keep Skip calling the existing _finish() path.
Replace the SmoothPageIndicator dots with a text counter of the current page and the total page count.
Do not change the rule copy or the language tiles.
```

### Login and password reset

**Phase 4.** Second prompt in Phase 4.

`UnifiedLogIn` (`lib/screen/widgets/auth/unified_log_in.dart`) is used for both roles. The password field uses `TextInputAction.done`, but `AuthTextField` has no `onFieldSubmitted`, so the keyboard Done key does not log in. Forgot password (`lib/screen/widgets/auth/forgot_password_screen.dart`) shows `authResetLinkSent` and then `Navigator.pop` in the same turn, so the confirmation disappears with the route. The save-password checkbox is 18×18 with `shrinkWrap`.

**Adjustment.** Pass `_handleLogin` as `onFieldSubmitted` on the password field, and wrap the form in `AutofillGroup` with email and password autofill hints. On a successful reset, pop first and show the snackbar on the login scaffold. Enlarge the checkbox row to a 44 px tap target.

**Checklist**

- [x] Keyboard Done on the password field calls `_handleLogin`.
- [x] Email and password fields have autofill hints inside an `AutofillGroup`.
- [x] A successful reset pops first, and the login screen shows `authResetLinkSent`.
- [x] A failed reset stays on the forgot-password screen with the email still filled.
- [x] The save-password row has at least a 44 px tap target.
- [x] Client and seller login both get the change, because both use `UnifiedLogIn`.

**Prompt**

```text
Implement the Login and password reset section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/widgets/auth/auth_ui.dart, lib/screen/widgets/auth/unified_log_in.dart, and lib/screen/widgets/auth/forgot_password_screen.dart.
Add onFieldSubmitted to AuthTextField and pass _handleLogin from the password field.
Wrap the login fields in AutofillGroup with email and password autofill hints.
On a successful password reset, pop back to login and show the existing authResetLinkSent snackbar on the login scaffold. On failure, stay on the reset screen.
Make the save-password checkbox row at least 44 px tall.
Do not change the login API calls.
```

### Email confirmation

**Phase 4.** Third prompt in Phase 4.

`OtpVerificationScreen` (`lib/screen/widgets/auth/otp_verification_screen.dart`) has no code field. It tells the user to open the email, and Resend is a `GestureDetector` with no cooldown. Back to log in calls `UnifiedLogIn().launch(context)`, which stacks another login on top of signup.

**Adjustment.** Disable Resend for 60 seconds after a successful send and show the remaining seconds in the label. Change Back to `context.go` on the role’s login route. Add an Open email app action with `url_launcher`.

**Checklist**

- [x] Resend is a button that disables for 60 seconds after a successful send.
- [x] The label shows the remaining seconds during the cooldown.
- [x] A failed resend does not start the cooldown.
- [x] Back uses `context.go` to the client or seller login route for the signup role.
- [x] Open email app launches the mail client.
- [x] Both client and seller signup pass the role into this screen.

**Prompt**

```text
Implement the Email confirmation section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/widgets/auth/otp_verification_screen.dart and the client and seller signup screens that open it.
Replace the Resend GestureDetector with a button that stays disabled for 60 seconds after a successful AuthService.resendSignupConfirmation, and show the remaining seconds in the label.
Do not start the cooldown when resend throws.
Change Back to log in so it context.go's to the matching role login route instead of pushing UnifiedLogIn.
Add an Open email app action with url_launcher.
Keep the screen as an email-confirmation screen. Do not add an OTP code field.
```

### Seller screens outside the shell

**Phase 4.** Last prompt in Phase 4.

Seller blue is applied only inside the seller `StatefulShellRoute` in `lib/router/app_router.dart`. Attendance, notifications, settings, order details, and chat inbox are root-navigator routes, so they fall back to the client green `kPrimaryColor`. Client tab labels are 11 px, one line, with ellipsis, so Dutch strings clip.

**Adjustment.** Extract the seller theme into one helper and wrap every seller root route with it. On narrow widths, drop the tab label and keep the icon plus a tooltip, and add `Semantics(label:, selected:)` so a clipped label is still announced.

**Checklist**

- [x] One helper builds the seller theme already used inside the seller shell.
- [x] Seller attendance, notifications, settings, order details, chat inbox, and seller profile routes use that theme.
- [x] Client routes stay on the green theme.
- [x] On narrow widths, bottom-nav tiles show the icon and a tooltip when the label would clip.
- [x] Each tile has `Semantics` with the label and selected state.

**Prompt**

```text
Implement the Seller screens outside the shell section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/router/app_router.dart.
Extract the existing seller Theme into one helper and wrap the seller root-navigator routes with it: attendance, notifications, settings, order details, chat inbox, and seller profile routes.
Leave client routes on the current theme.
On narrow widths, hide clipped bottom-nav labels and keep the icon plus a tooltip.
Add Semantics(label, selected) on each bottom-nav tile.
Do not change route paths.
```

## Client features

- [x] Post a job — Phase 1
- [x] My jobs — Phase 3
- [x] Job details — Phase 2
- [x] Applications inbox — Phase 3
- [x] Hire from the inbox — Phase 2
- [x] Contract details — Phase 2
- [x] Buy a service — Phase 1
- [x] Categories — Phase 3
- [x] Employer verification — Phase 3

### Post a job

**Phase 1.** Second prompt in Phase 1, after Edit profile.

`CreateNewJobPost` (`lib/screen/client screen/client job post/create_new_job_post.dart`) validates title, category, description, shift pair, and location on steps 0–2. Step 3 (budget) is the `default` branch and always returns null:

```dart
default:
  return null;
```

A reversed min/max, or text that is not a number, is still posted. The review card on that step does not show the budget.

**Adjustment.** Add a `case 3` that rejects a max below min, and rejects a field that has text but does not parse. Leave both fields empty if budget stays optional. Show the range on the review card with `JobPostsService.formatBudgetRange`. `_handlePost` already re-runs `_validateStep`, so Post will jump back to step 3.

**Checklist**

- [x] `_validateStep` case 3 rejects a max that is below min.
- [x] A non-empty field that does not parse as a number is rejected.
- [x] Both budget fields can stay empty.
- [x] The review card shows the formatted range from `JobPostsService.formatBudgetRange`.
- [x] Post still re-runs validation and returns the user to step 3 when the budget is invalid.
- [x] Steps 0–2 validation is unchanged.

**Prompt**

```text
Implement the Post a job section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/client screen/client job post/create_new_job_post.dart and ARB files if a new validation string is needed.
In _validateStep, replace the default branch with a budget case.
Reject a max below min, and reject a non-empty value that does not parse as a number.
Allow both budget fields to be empty.
Show the budget on the review card using JobPostsService.formatBudgetRange.
Keep the existing step 0–2 checks and the existing _handlePost validation loop.
```

### My jobs

**Phase 3.** Tenth prompt in Phase 3.

`ClientJobPost` (`lib/screen/client screen/client job post/client_job_post.dart`) filters by gig, full time, and part time in memory. If posts exist but none match the chip, the page shows `totalJobPostCount(0)` and an empty list, with no empty message. The card also hardcodes `Category:`, `General`, and `Untitled`, and shows the raw status string.

**Adjustment.** When `_jobPosts` is not empty and `_visibleJobPosts` is empty, show the same clear-filter empty state the contracts list already uses. Map status through `l10n.open` / `l10n.closed`, and use `l10n.categoryLabel`, `l10n.categoryGeneral`, and `l10n.untitled`.

**Checklist**

- [x] A type filter that matches nothing shows a clear-filter empty state.
- [x] Clear filter sets `_typeFilter` back so all posts show again.
- [x] A truly empty job list still offers Post a job.
- [x] Cards use `l10n.categoryLabel`, `l10n.categoryGeneral`, and `l10n.untitled`.
- [x] Status uses `l10n.open` and `l10n.closed`.

**Prompt**

```text
Implement the My jobs section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/client screen/client job post/client_job_post.dart.
When _jobPosts is not empty and _visibleJobPosts is empty, show EmptyStateWidget with a clear-filter action that sets _typeFilter to null.
Keep the existing Post a job empty state for when there are no posts at all.
Replace the hardcoded Category, General, and Untitled strings and the raw status text with the existing l10n keys used on JobDetails.
Do not change how jobs are loaded.
```

### Job details

**Phase 2.** First prompt in Phase 2.

`JobDetails` (`lib/screen/client screen/client job post/job_details.dart`): a failed `getJobPostDetails` only snackbars and leaves `_jobPost` null. The screen then treats a missing status as `open`, so Close job stays in the menu and can still call `closeJobPost`. The menu item also has no `value`; Close is wired through `Text.onTap` while the popup route is still open.

**Adjustment.** If loading finished and `_jobPost` is null, show `EmptyStateWidget` with Retry and no overflow menu. Give the menu item `value: 'close'` and call `_handleCloseJob` from `onSelected` after the menu pops.

**Checklist**

- [x] A failed load sets a failure flag and does not treat the job as open.
- [x] The failure state is `EmptyStateWidget` with Retry and no Close job menu.
- [x] Retry calls `_loadData`.
- [x] Close job is a menu item with `value: 'close'`, handled in `onSelected`.
- [x] The existing close confirmation dialog still runs before `closeJobPost`.

**Prompt**

```text
Implement the Job details section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/client screen/client job post/job_details.dart.
If _loadData fails and _jobPost is null, show EmptyStateWidget with Retry calling _loadData, and do not render the overflow menu.
Do not default a missing status to open.
Move Close job onto PopupMenuItem value 'close' and call the existing _handleCloseJob from onSelected.
Keep the existing close confirmation dialog.
```

### Applications inbox

**Phase 3.** Last prompt in Phase 3.

`ClientApplications` (`lib/screen/client screen/applications/client_applications.dart`) defaults the filter to pending. If every application is already accepted or rejected, the pending chip shows “no applications” and Post a job. `ClientOrderList` already distinguishes a truly empty list from a filtered empty list. This screen does not. Pull-to-refresh is also only attached when the filtered list has rows.

**Adjustment.** Keep Post a job only when `_applications` is empty. When the full list has rows and the chip matches none, show a filter-empty state whose action sets `_statusFilter = null`. Put `RubikRefreshIndicator` on that empty list too.

**Checklist**

- [x] Post a job appears only when `_applications` is empty.
- [x] A non-empty list with no rows for the current chip shows a filter-empty state.
- [x] That action clears `_statusFilter` and does not open the job form.
- [x] The filter-empty state can pull to refresh.
- [x] Hire and Reject on pending cards stay as they are.

**Prompt**

```text
Implement the Applications inbox section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/client screen/applications/client_applications.dart.
Follow the empty-versus-filtered-empty split already used in lib/screen/client screen/client orders/client_orders.dart.
Show Post a job only when _applications is empty.
When applications exist but the current chip matches none, show a filter-empty state whose action sets _statusFilter to null.
Wrap that empty list in RubikRefreshIndicator.
Do not change hire, reject, or chat actions.
```

### Hire from the inbox

**Phase 2.** Second prompt in Phase 2, after Job details.

Hiring from job details confirms, creates the order, then opens a sheet: Add instructions now or Send later, and passes location and attendance into `HireOnboardingEditorScreen`. Hiring from the applications card uses `JobOfferChatActions.acceptOffer` (`lib/core/utils/job_offer_chat_actions.dart`). The snackbar action is labeled Open contract, but it opens the editor, and it does not pass `job_posts` location or attendance mode. If `ensureDraft` fails, Save and Publish stay enabled and return immediately because `_packet` is null (`lib/screen/onboarding/hire_onboarding_editor_screen.dart`).

**Adjustment.** After an inbox hire, show the same post-hire sheet as job details, and pass `location`, `location_type`, and `AttendanceMode.effectiveForJobPost`. If you keep a snackbar action, point Open contract at the order details route. In the editor, if the packet failed to load, show Retry and hide Save and Publish.

**Checklist**

- [x] Inbox hire shows the same post-hire instructions sheet as `JobDetails`.
- [x] The editor receives job location, location type, and attendance mode.
- [x] An Open contract action opens the new client order, not the editor.
- [x] If the onboarding packet fails to load, the editor shows Retry and hides Save and Publish.
- [x] Hiring from job details keeps its current behavior.

**Prompt**

```text
Implement the Hire from the inbox section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/core/utils/job_offer_chat_actions.dart and lib/screen/onboarding/hire_onboarding_editor_screen.dart.
After acceptOffer succeeds, show the same post-hire sheet JobDetails uses, and pass location, location_type, and AttendanceMode.effectiveForJobPost into HireOnboardingEditorScreen.
If a snackbar action stays, label it with the existing open-contract string and open the client order details for the new order id.
In the editor, when loading finishes and _packet is null, show EmptyStateWidget with Retry and do not show Save or Publish.
Do not change JobDetails._handleAcceptOffer.
```

### Contract details

**Phase 2.** Third prompt in Phase 2.

`ClientOrderDetails` (`lib/screen/client screen/client orders/client_order_details.dart`): while a contract is active or pending, the bottom bar is a filled Waiting for delivery button whose handler is empty:

```dart
if (isOpenContract) {
  return Container(
    child: ButtonGlobalWithoutIcon(
      buttontext: l10n.waitingForDelivery,
      onPressed: () {},
    ),
  );
}
```

Message is only in the overflow menu. Approving a cancellation has no confirm dialog, unlike Mark job complete. A missing seller id reuses the review error string. `ClientSiteSetupPanel` (`lib/screen/widgets/client_site_setup_panel.dart`) still hardcodes Site setup, First-day, Edit, Attendance QR, Print at site, and Open.

**Adjustment.** On an open contract, make the bottom button Message and call `_handleMessageSeller`. Confirm before `respondToCancellation(approve: true)`. Use a chat-specific error when `sellerId` is null. Replace the six English literals in the site panel with the strings the order screen already uses.

**Checklist**

- [x] Active and pending contracts use a Message bottom button that calls `_handleMessageSeller`.
- [x] Approving cancellation shows a confirm dialog before the request.
- [x] Keeping the contract stays one tap.
- [x] A missing seller id shows a chat error, not the review-missing-seller string.
- [x] `ClientSiteSetupPanel` uses existing l10n strings for its six English labels.
- [x] Mark complete and Write a review stay as they are.

**Prompt**

```text
Implement the Contract details section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/client screen/client orders/client_order_details.dart and lib/screen/widgets/client_site_setup_panel.dart, plus ARB files only if a chat-missing-seller string does not already exist.
For active or pending orders, replace the Waiting for delivery button with Message calling _handleMessageSeller.
Before approving a cancellation, show an AlertDialog with the same shape as mark-complete. Leave keep-contract as one tap.
When sellerId is missing, show a chat-specific error.
Replace the hardcoded English labels in ClientSiteSetupPanel with existing l10n keys.
Do not change delivered or completed bottom bars.
```

### Buy a service

**Phase 1.** Third prompt in Phase 1.

`ClientServiceDetails` (`lib/screen/client screen/client service details/client_service_details.dart`): Order Now is hardcoded English and calls `OrdersService.createOrder` with no in-flight flag and no confirm. A second tap before the first call returns creates another order. Success only pops the screen.

**Adjustment.** Add `_placingOrder`, ignore further taps while it is true, and confirm price and delivery days before `createOrder`. On success, open the new contract if the insert returns an id. If the service or seller is missing, snackbar `errorPlacingOrder` instead of returning silently.

**Checklist**

- [x] The button label uses l10n, not the literal `Order Now`.
- [x] A confirm dialog shows price and delivery days before `createOrder`.
- [x] `_placingOrder` blocks a second tap until the call finishes.
- [x] The button is disabled while the order is being created.
- [x] Success opens the new client order when an id is returned.
- [x] Missing service or seller shows `errorPlacingOrder`.

**Prompt**

```text
Implement the Buy a service section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/client screen/client service details/client_service_details.dart, and OrdersService.createOrder only if it does not already return the new order id.
Localize the Order Now label.
Add _placingOrder so a second tap cannot create another order.
Show a confirm dialog with price and delivery days before createOrder.
On success, open the new client order details when an id is returned. Otherwise pop as it does now.
If service or seller is missing, show errorPlacingOrder instead of returning silently.
Clear _placingOrder in finally.
```

### Categories

**Phase 3.** Ninth prompt in Phase 3.

Home tiles open `ClientAllCategories` (`lib/screen/client screen/client home/client_all_categories.dart`) and only pre-fill the search box. Each category row is a bordered `Row` with no `onTap`. A load error clears the list and then shows “no categories yet.”

**Adjustment.** Wrap each row in `InkWell` and open `CustomSearchDelegate` with that category name, the same delegate the home search uses. On load failure, show Retry instead of the empty-catalog message.

**Checklist**

- [x] Tapping a category opens marketplace search for that category name.
- [x] A failed load shows Retry and does not show “no categories yet.”
- [x] A search with no matches still shows the no-match message.
- [x] Home category tiles can still open this list.

**Prompt**

```text
Implement the Categories section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/client screen/client home/client_all_categories.dart.
Wrap each category row in InkWell and open CustomSearchDelegate with that category name, the same way client_home_screen.dart opens search.
On load failure, set a failure flag and show EmptyStateWidget with Retry.
Show the existing no-categories message only when the request succeeds and the list is empty.
Do not change the home category tiles.
```

### Employer verification

**Phase 3.** Second prompt in Phase 3, after Splash.

`EmployerVerificationScreen` (`lib/screen/client screen/client profile/employer_verification_screen.dart`): a failed `_load` snackbars and then renders the form as unverified, so the employer can submit a new ID on top of a failed read. `_previewImage` shows `_submittedDocUrl` regardless of path. Switching Personal ID / Company clears the new pick but still shows the stored file, so a company document can sit under the personal-ID title.

**Adjustment.** Show the stored photo only when the selected path matches the stored `verify_type`. On load failure, show Retry and do not render the submit form.

**Checklist**

- [x] A failed load shows Retry and hides the submit form.
- [x] The stored document preview appears only when the selected path matches the stored `verify_type`.
- [x] Switching path still clears the newly picked file.
- [x] Submit still requires a newly picked file.

**Prompt**

```text
Implement the Employer verification section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/client screen/client profile/employer_verification_screen.dart.
If _load fails, show EmptyStateWidget with Retry and do not render the unverified form.
In _previewImage, show the stored document URL only when the selected path matches the stored verify_type.
Keep clearing the new pick when the segmented control changes.
Keep the rule that Submit requires a newly picked file.
```

## Seller features

- [x] Edit profile — Phase 1
- [x] Seller home — Phase 3
- [x] Contracts — Phase 3
- [x] Contract details and delivery — Phase 2
- [x] Find jobs and job details — Phase 3
- [x] My applications — Phase 3
- [x] Job alerts — Phase 3
- [x] Attendance — Phase 2
- [x] Favourites — Phase 2
- [x] Identity verification — Phase 3

### Edit profile

**Phase 1.** First prompt. Start here.

`SellerEditProfile` (`lib/screen/seller screen/profile/seller_edit_profile_details.dart`): save writes public location to null, and `updateSellerProfile` does it again because `clearPublicCountryCity` defaults to true in `lib/services/profile_service.dart`:

```dart
await ProfileService.updateProfile({
  'name': _nameController.text.trim(),
  'phone': _phoneController.text.trim(),
  'gender': _selectedGender,
  'country': null,
  'city': null,
});
```

Find jobs distance and job alerts read those fields. The edit form has no city control, so the seller cannot see or restore what save removed. An empty name is also saved.

**Adjustment.** Remove the null country and city from this map, and call `updateSellerProfile(..., clearPublicCountryCity: false)`. Require a non-empty name before `_isSaving` is set. Leave city and coordinates to the map picker, which already writes them.

**Checklist**

- [x] Profile save does not send `country: null` or `city: null`.
- [x] `updateSellerProfile` is called with `clearPublicCountryCity: false` from this screen.
- [x] An empty name is rejected before the save request.
- [x] The map picker can still update city, country, and coordinates.
- [x] Find jobs distance and job alerts still read the saved city after a profile save.

**Prompt**

```text
Implement the Edit profile section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/seller screen/profile/seller_edit_profile_details.dart.
Remove country: null and city: null from the updateProfile map in _handleSave.
Call updateSellerProfile with clearPublicCountryCity: false.
If the trimmed name is empty, show a snackbar and return before _isSaving is set.
Do not add a city field to this form, and do not change MapLocationPickerScreen.
```

### Seller home

**Phase 3.** Fourth prompt in Phase 3.

`SellerHomeScreen` (`lib/screen/seller screen/seller home/seller_home_screen.dart`): a failed overview load snackbars and leaves `_overview` as `{}`, so every stat renders as `0` or `$0`. Application chips paint anything other than accepted or rejected as pending, including withdrawn. Every application row opens the full applications list. The “delivered, awaiting approval” row goes to `/seller/orders` with no status, which lands on All.

**Adjustment.** Add a failed-load flag and show Retry in place of the zeroed overview. Add a `withdrawn` arm using the same colors as `SellerApplications`. Open each home application on that job’s `BuyerRequestDetails`, then reload. Pass `status=delivered`, `status=active`, or `status=completed` into `SellerOrderList` from the attention and stat taps.

**Checklist**

- [x] A failed overview load shows Retry instead of zeros.
- [x] Withdrawn applications use the withdrawn colors from `SellerApplications`.
- [x] Tapping a home application opens that job and reloads home on return.
- [x] Delivered, active, and completed taps open `/seller/orders` on that status tab.
- [x] `SellerOrderList` reads the status query and selects that tab on open.

**Prompt**

```text
Implement the Seller home section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/seller screen/seller home/seller_home_screen.dart, lib/screen/seller screen/orders/seller_orders.dart, and the /seller/orders route in lib/router/app_router.dart.
If the home overview request fails and there is no overview data, show EmptyStateWidget with Retry instead of zero stats.
Add a withdrawn status style matching SellerApplications.
Open each home application row on BuyerRequestDetails for that job, then reload home when it pops.
Add an optional initial status to SellerOrderList and route delivered, active, and completed taps to /seller/orders?status=...
Do not change how the overview numbers are calculated.
```

### Contracts

**Phase 3.** Fifth prompt in Phase 3.

`SellerOrderList` (`lib/screen/seller screen/orders/seller_orders.dart`): a failed `_loadOrders` leaves `_orders` empty, so the All tab says there are no contracts and offers Browse jobs. The client select is `name` only, while the card still reads `profile_image_url`, so avatars never have a photo. There is no Cancelled chip.

**Adjustment.** When the request fails and the list is empty, show Retry and skip the empty-account copy. Add `'cancelled'` to `_statusTabs` (`getSellerOrders` already filters by status). Extend the select to `name, profile_image_url`.

**Checklist**

- [x] A failed load with an empty list shows Retry, not “no contracts” or Browse jobs.
- [x] A successful empty All tab still offers Browse jobs.
- [x] A Cancelled chip filters to cancelled contracts.
- [x] Contract cards show the client profile photo when `profile_image_url` exists.

**Prompt**

```text
Implement the Contracts section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/seller screen/orders/seller_orders.dart and lib/services/seller_orders_service.dart.
Add a load-failed flag. When the request fails and _orders is empty, show EmptyStateWidget with Retry.
Keep Browse jobs only for a successful empty All tab, and keep Clear filters for a successful empty filtered tab.
Add a cancelled chip to _statusTabs.
Extend the client select to name, profile_image_url and use it in the card avatar.
```

### Contract details and delivery

**Phase 2.** Fourth prompt in Phase 2.

`SellerOrderDetails` (`lib/screen/seller screen/orders/seller_order_details.dart`): if `_loadOrder` fails, `_order` stays null and status falls through to `pending`, so the bottom bar still offers Request cancel and Deliver work. Deliver is not tied to `_actionBusy`. Withdraw cancellation calls the service with no dialog. The shift row label is the literal `Shift`.

**Adjustment.** If `_order` is null after load, show Retry and no action bar. Disable Deliver while `_actionBusy` is true. Confirm before `withdrawCancellation`, using the same dialog pattern as application withdraw.

**Checklist**

- [x] A failed order load shows Retry and no bottom action bar.
- [x] Deliver is disabled while `_actionBusy` is true.
- [x] Withdraw cancellation asks for confirmation before the request.
- [x] The shift row uses a localized label.
- [x] A successful load still shows Request cancel and Deliver work for an open contract.

**Prompt**

```text
Implement the Contract details and delivery section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/seller screen/orders/seller_order_details.dart and ARB files if the shift label is missing.
If loading finished and _order is null, show EmptyStateWidget with Retry and a null bottomNavigationBar.
Disable the Deliver button while _actionBusy is true by passing null to onPressed.
Confirm with an AlertDialog before withdrawCancellation, using the same pattern as application withdraw.
Replace the hardcoded Shift label with the existing localized shift string.
Do not change SellerDeliverOrder.
```

### Find jobs and job details

**Phase 3.** Sixth prompt in Phase 3.

`BuyerRequestDetails` (`lib/screen/seller screen/buyer request/buyer_request_details.dart`): a failed job load leaves `_jobPost` null, and the screen treats status as `open`, so Submit offer stays enabled. Block reasons and several row labels (Category, Skills, Budget, Workers needed, Shift, Job posted, Read more) are hardcoded English. The body has no pull-to-refresh.

**Adjustment.** If the job is null after load, show Retry and hide the offer button. Return the existing localized strings from `applyBlockedReason`. Wrap the body in `RubikRefreshIndicator(onRefresh: _loadDetails)`.

**Checklist**

- [x] A failed job load shows Retry and hides Submit offer.
- [x] Closed, own-job, and already-applied reasons use existing l10n strings.
- [x] Pull to refresh reloads the job.
- [x] Category, skills, budget, workers, shift, posted date, and read more/less use existing l10n keys.
- [x] Returning from `CreateCustomerOffer` still reloads and can show “already submitted.”

**Prompt**

```text
Implement the Find jobs and job details section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/seller screen/buyer request/buyer_request_details.dart.
If loading finished and _jobPost is null, show EmptyStateWidget with Retry and do not build the offer button.
Use existing l10n strings in applyBlockedReason and for the hardcoded detail labels and read more/less.
Wrap the details body in RubikRefreshIndicator(onRefresh: _loadDetails).
Do not change CreateCustomerOffer validation.
```

### My applications

**Phase 3.** Seventh prompt in Phase 3.

`SellerApplications` (`lib/screen/seller screen/applications/seller_applications.dart`): opening a job does not await the route, so status stays stale until a manual refresh. The chat icon is shown for rejected and withdrawn applications. A failed load looks like “no applications.”

**Adjustment.** Await `BuyerRequestDetails`, then `_load(showLoader: false)`. Show chat only for `pending` and `accepted`. On load failure, show Retry.

**Checklist**

- [x] Returning from a job reloads the applications list without a full-screen loader.
- [x] Chat shows only for pending and accepted applications.
- [x] A failed load shows Retry, not “no applications.”
- [x] Withdraw still confirms and updates the row to withdrawn.

**Prompt**

```text
Implement the My applications section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/seller screen/applications/seller_applications.dart.
Await BuyerRequestDetails.launch and then call _load(showLoader: false) if the widget is still mounted.
Show the chat icon only when status is pending or accepted.
On load failure, show EmptyStateWidget with Retry instead of the empty-applications state.
Keep the existing withdraw confirmation.
```

### Job alerts

**Phase 3.** Eighth prompt in Phase 3.

`SellerJobAlertsScreen` (`lib/screen/seller screen/job alerts/seller_job_alerts_screen.dart`): `_load` has no `catch`. A thrown error leaves `_rules` empty, so the empty state says there are no alerts and the FAB still creates one. The editor’s `_bootstrap` (`seller_job_alert_editor_screen.dart`) does the same and opens the form with an empty category and skill catalog.

**Adjustment.** On list failure, show Retry and hide the FAB. In the editor, show Retry above the form when the catalog fails to load. Disable each rule’s switch while `setEnabled` is in flight.

**Checklist**

- [x] A failed rule list shows Retry and hides the create button.
- [x] A successful empty list still shows the create action.
- [x] A switch cannot be toggled again while `setEnabled` is in flight.
- [x] A failed editor bootstrap shows Retry instead of an empty category and skill form.
- [x] Distance validation in the editor stays as it is.

**Prompt**

```text
Implement the Job alerts section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/seller screen/job alerts/seller_job_alerts_screen.dart and lib/screen/seller screen/job alerts/seller_job_alert_editor_screen.dart.
Catch list failures, show EmptyStateWidget with Retry, and hide the FloatingActionButton on that state.
Keep the create button when the list succeeds and is empty.
Disable each rule switch while setEnabled is running for that rule.
In the editor, if category or skill loading fails, show Retry and do not present an empty catalog as a valid form.
Do not change the distance-alert location check.
```

### Attendance

**Phase 2.** Last prompt in Phase 2.

`AttendanceActionsCard` (`lib/screen/attendance/attendance_actions_card.dart`): self-report clock-out records the punch and creates an hour report with one tap. An unreadable QR returns with no message in `AttendanceScanScreen`:

```dart
final token = AttendanceService.parseTokenFromPayload(raw);
if (token == null) return;
```

The scanner uses `noDuplicates`, so a bad code may never fire again until the camera restarts. Clock-out success in `AttendanceConfirmScreen` also appends the English sentence `Hours sent for employer review.` A failed hub load looks like “no onsite jobs.”

**Adjustment.** Confirm before a self-report clock-out. Clock-in can stay one tap. When the token is null, snackbar a localized “this is not an attendance code” and restart the camera after a short pause. Put the hours-sent sentence in the ARB files. On the hub, show Retry only when the request failed.

**Checklist**

- [x] Self-report clock-out asks for confirmation before recording the punch.
- [x] Self-report clock-in stays one tap.
- [x] An unreadable QR shows a localized snackbar and the camera can scan again.
- [x] Clock-out success uses an ARB string for “hours sent for employer review” in English and Dutch.
- [x] A failed hub load shows Retry. A successful empty hub still says there are no onsite jobs.

**Prompt**

```text
Implement the Attendance section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/attendance/attendance_actions_card.dart, lib/screen/attendance/attendance_scan_screen.dart, lib/screen/attendance/attendance_confirm_screen.dart, lib/screen/attendance/seller_attendance_hub_screen.dart, and the English and Dutch ARB files.
Confirm with a dialog before a self-report clock-out. Leave clock-in as one tap.
When AttendanceService.parseTokenFromPayload returns null, show a localized snackbar and restart the scanner so the same code can be detected again.
Replace the hardcoded "Hours sent for employer review." sentence with a new l10n string.
On the hub, show Retry only when the job request fails. Keep the existing empty state when the request succeeds with no jobs.
Do not change the QR confirm screen's GPS checks.
```

### Favourites

**Phase 2.** Seventh prompt in Phase 2.

`SellerFavouriteList` (`lib/screen/seller screen/favourite/seller_favourite_list.dart`): remove deletes immediately by list index, with no undo. If a refresh reorders the list first, `removeAt` can drop the wrong row. The bookmark tooltip is `removedFromFavourites`, which is the success string.

**Adjustment.** Remove by favourite id, show a snackbar with an undo action that calls `FavouriteService.toggleFavourite`, and set the tooltip to a remove label.

**Checklist**

- [x] Removal finds the row by favourite id, not by the index captured at tap time.
- [x] The row disappears immediately, and the snackbar has an undo action.
- [x] Undo restores the row and calls `FavouriteService.toggleFavourite`.
- [x] A failed delete puts the row back and shows the existing error snackbar.
- [x] The bookmark tooltip is a remove label, not the past-tense success string.

**Prompt**

```text
Implement the Favourites section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/seller screen/favourite/seller_favourite_list.dart and ARB files if a remove-tooltip string is missing.
Remove a favourite by its id at the moment of removal, not by a stale list index.
Remove the row immediately, then call FavouriteService.removeFavourite.
Show a snackbar with an undo action that inserts the row back and calls FavouriteService.toggleFavourite.
On failure, restore the row and show the existing error snackbar.
Change the IconButton tooltip from the success string to a remove label.
```

### Identity verification

**Phase 3.** Third prompt in Phase 3.

`SellerIdentityVerificationScreen` (`lib/screen/seller screen/profile/seller_identity_verification_screen.dart`): a failed load still builds the form with `_status = 'unverified'`, so a network error looks like “not submitted.”

**Adjustment.** Gate the form on a load-failed flag and show Retry.

**Checklist**

- [x] A failed load does not set the status to unverified.
- [x] The failure state shows Retry and hides the submit form.
- [x] A successful unverified response still shows the submit form.

**Prompt**

```text
Implement the Identity verification section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change the seller identity verification screen.
If the status load fails, set a load-failed flag, show EmptyStateWidget with Retry, and do not build the form as unverified.
Show the current unverified form only when the request succeeds with an unverified status.
Do not change the submit or upload flow.
```

## Shared work features

- [x] Chat — Phase 5
- [x] Notifications — Phase 5
- [x] Reviews — Phase 1
- [x] Off-app payment — Phase 2
- [x] Cancellation and delivery files — Phase 2
- [x] Search, categories, and the map pin — Phase 5
- [x] Report a user — Phase 5

### Chat

**Phase 5.** First prompt in Phase 5.

`ChatInbox` (`lib/screen/seller screen/seller message/chat_inbox.dart`): send already retries failed messages. Attach is a 20 px paperclip with no tooltip, and `_pickAndSendImage` uses `ImageSource.gallery` only. The empty seller inbox (`chat_list.dart`) has title and subtitle only.

**Adjustment.** On attach, open a sheet with Gallery and Camera, using the same picker pattern as the review screen. Give the control a 44 px target and a tooltip. If permission is denied, snackbar with an App settings action, matching the GPS snackbar on the attendance confirm screen. On an empty seller inbox, add Browse jobs to `/seller/find-jobs`.

**Checklist**

- [x] Attach opens a sheet with Gallery and Camera.
- [x] The attach control is at least 44 px and has a tooltip.
- [x] A denied camera or photo permission shows a snackbar with an App settings action.
- [x] The control stays disabled while an attachment is uploading.
- [x] The empty seller inbox has a Browse jobs action to `/seller/find-jobs`.
- [x] Failed message retry stays as it is.

**Prompt**

```text
Implement the Chat section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/seller screen/seller message/chat_inbox.dart and the chat list empty state in lib/screen/seller screen/seller message/chat_list.dart.
On attach, show a bottom sheet with Gallery and Camera, reusing the picker pattern from the client review screen.
Give the attach control a 44 px target and a localized tooltip.
If permission is denied, show a snackbar with an App settings action, matching attendance_confirm_screen.dart.
On the empty seller inbox, add a Browse jobs action that goes to /seller/find-jobs.
Keep the existing failed-send retry and the upload lock.
```

### Notifications

**Phase 5.** Second prompt in Phase 5.

`NotificationListScreen` (`lib/screen/widgets/notification_list_screen.dart`): unread count is only on the home app bar. `ClientShellAppBar` on chat, jobs, orders, and talent has no bell. Every row uses the same bell icon. Read all calls `markAllAsRead` with no in-progress state. The in-app banner (`lib/core/notifications/notification_in_app_banner.dart`) only closes by tap or the close button.

**Adjustment.** Add the same unread action from the home app bar to `ClientShellAppBar`. Map `notification.type` to an icon (chat, work, QR, star). Disable Read all and show a progress indicator while it runs. Make the banner vertically dismissible.

**Checklist**

- [x] Chat, jobs, orders, and talent app bars show the same unread bell as home, for both roles.
- [x] List rows use a type-specific icon for chat, work, attendance, and reviews.
- [x] Read all is disabled and shows progress while `markAllAsRead` runs.
- [x] A failed mark-all shows a snackbar and leaves the unread state unchanged.
- [x] The in-app banner can be swiped away.

**Prompt**

```text
Implement the Notifications section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/widgets/notification_list_screen.dart, the shell app bar used by client and seller tabs, and lib/core/notifications/notification_in_app_banner.dart.
Add the existing home unread bell action to ClientShellAppBar and the seller equivalents, routing to that role's notifications route.
Map notification.type to an icon for chat, work, QR, and reviews. Keep the bell for unknown types.
Disable Read all and show a progress indicator while markAllAsRead runs. Snackbar on failure.
Make the in-app banner Dismissible vertically.
Do not change NotificationNavigation tap targets.
```

### Reviews

**Phase 1.** Last prompt in Phase 1.

Both `ClientOrderReview` (`lib/screen/client screen/client review/client_review.dart`) and `SellerOrderReview` (`lib/screen/seller screen/orders/seller_order_review.dart`) let the user pick a photo and show a preview. Publish never reads `_pickedImage`. `submitClientOrderReview` and `submitSellerOrderReview` in `lib/services/orders_service.dart` write rating and comment only.

**Adjustment.** Remove the photo picker until a review image column and upload exist. If you add storage in the same change, upload first, pass the URL into the insert, and do not submit if the upload fails. Disable the button with `onPressed: null` while submitting. The current `onPressed: () {}` still looks tappable.

**Checklist**

- [x] Client and seller review screens no longer show a photo picker.
- [x] Publish sends only the fields `OrdersService` already stores: rating, comment, and the related ids.
- [x] Publish uses `onPressed: null` while submitting.
- [x] A zero-star review is still blocked.
- [x] A duplicate review still shows the existing already-submitted message.

**Prompt**

```text
Implement the Reviews section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/client screen/client review/client_review.dart and lib/screen/seller screen/orders/seller_order_review.dart.
Remove the optional photo picker, preview, and unused _pickedImage state from both screens.
Do not add upload or a new database column.
While submitting, pass null to onPressed instead of an empty closure.
Keep the star requirement and the duplicate-review snackbar.
```

### Off-app payment

**Phase 2.** Fifth prompt in Phase 2.

`OrderPaymentReceivedCard` (`lib/screen/widgets/order_payment_received_card.dart`) records that money moved outside the app. Undo is a `TextButton` that clears the shared paid flag immediately.

**Adjustment.** Confirm before `_setReceived(false)`. The dialog body should say this only clears the record. Keep the existing `paymentReceivedCleared` snackbar.

**Checklist**

- [x] Undo opens a confirm dialog before clearing payment received.
- [x] The dialog says this only clears the in-app record.
- [x] Confirm still calls `_setReceived(false)` and shows `paymentReceivedCleared`.
- [x] The button stays disabled while `_busy` is true.
- [x] Mark paid is unchanged.

**Prompt**

```text
Implement the Off-app payment section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change lib/screen/widgets/order_payment_received_card.dart and ARB files if the confirm body string is missing.
Before undo, show a confirm dialog whose body says this only clears the payment record.
Call _setReceived(false) only when the dialog returns true.
Keep the existing paymentReceivedCleared snackbar and the _busy lock.
Do not add a bKash, PayPal, or other payment-provider flow.
```

### Cancellation and delivery files

**Phase 2.** Sixth prompt in Phase 2.

`OrderCancellationSheet` (`lib/screen/widgets/order_cancellation_sheet.dart`) keeps Submit enabled under the minimum note length. It sets submitting and pops before the request runs, so a failed cancellation discards the note. In `OrderDeliveryPanel` (`lib/screen/widgets/order_delivery_panel.dart`), non-image files render `_FileChip` as a static `Container` with no URL and no tap. A broken image preview falls back to the same chip.

**Adjustment.** Disable Submit until the note reaches `minNoteLength`, and pop only after `requestCancellation` succeeds. Pass `attachmentUrl` into `_FileChip` and open it with `launchUrl` in an external app, including the image `errorBuilder` fallback.

**Checklist**

- [x] Submit stays disabled until the note reaches `OrderCancellationReason.minNoteLength`.
- [x] The sheet pops only after the cancellation request succeeds.
- [x] A failed request keeps the note on screen.
- [x] Submit and Back use `onPressed: null` while the request is running.
- [x] Delivery file chips, including a broken image fallback, open `attachmentUrl` externally.

**Prompt**

```text
Implement the Cancellation and delivery files section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/widgets/order_cancellation_sheet.dart, the seller order details caller that submits it, and lib/screen/widgets/order_delivery_panel.dart.
Disable cancellation Submit until the note length reaches OrderCancellationReason.minNoteLength.
Pop the sheet only after requestCancellation succeeds, and keep the note when it fails.
Pass null to onPressed while submitting.
Pass attachmentUrl into _FileChip and open it with launchUrl in an external app, including the image errorBuilder fallback.
Add an open icon so the chip looks tappable.
```

### Search, categories, and the map pin

**Phase 5.** Third prompt in Phase 5.

`CustomSearchDelegate` (`lib/screen/client screen/search/search.dart`) defaults its hint to English `Search services or freelancers` and shows `e.toString()` in the results. `CategoryPickerField` (`lib/screen/widgets/category_picker_field.dart`) hardcodes Category, Search categories, the no-match line, and Add category. That add row sits inside the non-empty list, so a failed search hides the only way to add a category. `MapLocationPickerScreen` (`lib/screen/widgets/map_location_picker_screen.dart`) hardcodes the GPS snackbars. When GPS is off, the first move calls `_currentGpsLatLng(showErrors: false)`, so the user lands on the fallback map with no explanation.

**Adjustment.** Default the search hint from l10n at the call site, and show only `couldNotLoadResults` plus Retry. Keep Add category visible under an empty search. Replace the category and GPS strings with l10n, and on first open with GPS off and no initial pin, show the location-services snackbar once.

**Checklist**

- [x] Search hint comes from l10n when the caller does not pass one.
- [x] A search failure shows `couldNotLoadResults` and Retry, not the raw exception.
- [x] Add category stays visible when the category search matches nothing.
- [x] Category picker labels use l10n in English and Dutch.
- [x] GPS errors use l10n, including the Settings action.
- [x] Opening the map with GPS off and no initial pin shows the location-services snackbar once.

**Prompt**

```text
Implement the Search, categories, and the map pin section in docs/FEATURE_UX_ADJUSTMENTS.md.
Change lib/screen/client screen/search/search.dart, lib/screen/widgets/category_picker_field.dart, lib/screen/widgets/map_location_picker_screen.dart, and the English and Dutch ARB files.
Default the search hint from l10n at the call site.
On search failure, log the exception and show only couldNotLoadResults plus the existing Retry button.
Keep Add category visible when the category search is empty.
Replace the hardcoded category picker and GPS snackbar strings with l10n.
If the map opens with GPS off and no initial position, show the location-services snackbar once.
Do not change the 350 ms search debounce or the map confirm result.
```

### Report a user

**Phase 5.** Last prompt.

`ReportUserScreen` (`lib/screen/widgets/report_user_screen.dart`, reached from client and seller report flows): a note shorter than 10 characters only raises a snackbar.

**Adjustment.** Set `errorText` on the details field when the note is too short, so the reason stays next to the field.

**Checklist**

- [x] A note shorter than 10 characters sets `errorText` on the details field.
- [x] The error clears when the note becomes long enough.
- [x] Submit still sends the report when the note is valid.
- [x] Client and seller report entry points both use this screen, so both get the change.

**Prompt**

```text
Implement the Report a user section in docs/FEATURE_UX_ADJUSTMENTS.md.
Only change the shared report screen that validates the note length.
When the details note is shorter than 10 characters, set errorText on that field and do not rely only on a snackbar.
Clear the error when the note reaches the minimum length.
Keep the existing submit request for a valid note.
Do not change the client or seller screens that open this report form.
```

## After the last phase

Tick the phase checklists in [Phasing](#phasing) as you finish each prompt. Finish the current phase before starting the next one. Phase 1 is the only phase that changes what is stored. Phases 2 and 3 change what a tap or a failed request is allowed to do. Phases 4 and 5 are safe to pause between prompts.
