# Ease of use

Small follow-ups from using the signed-in employer and freelancer apps. The screens already do the work. These changes remove mixed signals: a freelancer page that turns orange, two names for one place, and empty data shown as the word "none."

Do not add buttons, filters, or steps. Each prompt is one change.

How to use this file:

1. Finish one phase before starting the next. The order is below.
2. Inside a phase, copy each **Prompt** in the listed order, one prompt per chat.
3. Tick that feature’s checklist only after the behavior in the prompt is true in the app.
4. Tick the phase when every feature in it is done.

## Phasing

Do the phases in order. Phase 1 changes color. Phase 2 changes names and which login opens. Later phases remove noise and shorten the freelancer home. Mixing them in one chat makes it easy to restyle a screen whose title is about to change.

| Phase | Goal | Prompts | Stop when |
|-------|------|---------|-----------|
| 1 | One color for the signed-in person | 2 | Freelancer My shifts and Attendance stay cyan, including their buttons. Employer screens stay orange |
| 2 | One name, and the login door matches the role | 2 | Applications is the only name for that screen, the menu says Settings, and login shows Employer or Freelancer |
| 3 | Less noise | 3 | A job with no description hides that line, Find Jobs has one bell, and only the open tab is selected |
| 4 | A shorter freelancer home | 1 | The first screen shows whether you are clocked in and the next shift. The six totals open from the work tracker |

### Phase 1 — One color

Copy these prompts in this order. My shifts is first because that route is not wrapped in the seller theme at all. Attendance is already wrapped, but its buttons are still hardcoded orange.

- [x] [My shifts color](#my-shifts-color)
- [x] [Attendance color](#attendance-color)

**Exit.** A signed-in freelancer can open My shifts and Attendance and stay in the cyan seller theme. Primary buttons, chips, and links on those screens use cyan. Employer screens stay orange.

### Phase 2 — Names and the login door

Copy these prompts in this order. Names first, so the login chip uses the same words as the rest of the app.

- [x] [One name](#one-name)
- [x] [Login role](#login-role)

**Exit.** The home shortcut, the menu, and the screen title all say Applications (Dutch: Aanmeldingen). The menu says Settings. Choosing Freelancer and tapping "I already have an account" opens a cyan login with a Freelancer chip. Choosing Employer opens an orange login with an Employer chip.

### Phase 3 — Less noise

Copy these prompts in this order.

- [x] [Empty job text](#empty-job-text)
- [x] [One bell](#one-bell)
- [x] [Selected tab](#selected-tab)

**Exit.** Find Jobs does not show the word "none" as a description. Its header has the notifications bell only, and job alerts are a labeled action. On both shells, a screen reader announces only the open tab as selected.

### Phase 4 — Shorter freelancer home

- [x] [Freelancer home](#freelancer-home)

**Exit.** On a phone, the freelancer home shows the next action without six stat tiles above the shift list. Those totals are still available from the work tracker.

## Shared

- [x] My shifts color — Phase 1
- [x] Attendance color — Phase 1
- [x] One name — Phase 2
- [x] Login role — Phase 2
- [x] Empty job text — Phase 3
- [x] One bell — Phase 3
- [x] Selected tab — Phase 3
- [x] Freelancer home — Phase 4

### My shifts color

**Phase 1.** First prompt in Phase 1.

`SellerApplications` is a root route in `lib/router/app_router.dart` (`AppRoutes.sellerApplications`). Unlike order details, chat, and settings, it is not passed through `withSellerTheme`, so the page falls back to the employer orange `kPrimaryColor`. The screen title is "My shifts." The All chip and the rates (€3/hr, €20/hr) are orange. The bottom tab bar is not on this screen, because it is pushed on top of the shell.

**Adjustment.** Wrap this route with the existing `withSellerTheme` helper. On `lib/screen/seller screen/applications/seller_applications.dart`, replace hardcoded orange (`kPrimaryColor`) for the selected filter, status chips, and rates with the theme primary, which is cyan inside that wrapper. Leave the employer applications screen orange.

**Checklist**

- [x] `/seller/applications` is built with `withSellerTheme`.
- [x] The selected filter, pending status, and rate text are cyan.
- [x] Employer applications stay orange.
- [x] The screen is still pushed above the tab bar. The route path does not change.

**Prompt**

```text
Implement the My shifts color section in docs/UX_EASE_OF_USE.md.
Change lib/router/app_router.dart and lib/screen/seller screen/applications/seller_applications.dart.
Wrap the seller applications route with the existing withSellerTheme helper.
Replace hardcoded kPrimaryColor on that screen's selected filter, status chips, and rates with the theme primary.
Leave the employer applications screen on orange.
Do not change the route path, and do not put this screen inside the bottom tab bar.
```

### Attendance color

**Phase 1.** Second prompt in Phase 1.

`SellerAttendanceHubScreen` is already wrapped in `withSellerTheme` in `lib/router/app_router.dart`, but `lib/screen/attendance/seller_attendance_hub_screen.dart` paints "Open contract," the time-out mark, and at least one button with `kPrimaryColor` (orange). The scan action is a separate green. On a signed-in freelancer this page sits between a cyan home and an orange link.

**Adjustment.** Use the theme primary (`kSellerPrimary` while wrapped) for the scan action, "Open contract," and the other primary marks on this screen. Do not introduce a third green. Employer attendance, if any, stays on the employer theme.

**Checklist**

- [x] Scan attendance QR uses cyan.
- [x] "Open contract" uses cyan.
- [x] No primary control on this screen uses `kPrimaryColor` while the seller theme is applied.
- [x] Clock-in state copy is unchanged ("Not clocked in," "No punches yet today").

**Prompt**

```text
Implement the Attendance color section in docs/UX_EASE_OF_USE.md.
Change lib/screen/attendance/seller_attendance_hub_screen.dart.
The route is already wrapped in withSellerTheme. Replace hardcoded kPrimaryColor on the scan action, Open contract, and other primary marks with the theme primary so a freelancer sees cyan.
Do not add a separate green for the scan button.
Do not change clock-in copy or the attendance API calls.
```

### One name

**Phase 2.** First prompt in Phase 2.

The freelancer home shortcut uses `applications` ("Applications" / "Aanmeldingen"). The screen title and menu use `myApplications` ("My shifts" / "Mijn shifts"). The menu item `settings` is "Setting" in English and already "Instellingen" in Dutch.

**Adjustment.** Point the home shortcut, the menu, and the screen title at one label: Applications in English and Aanmeldingen in Dutch. Change the English `settings` value to "Settings." Leave the Dutch settings string as it is.

**Checklist**

- [x] The freelancer home shortcut, menu entry, and screen title all read Applications in English.
- [x] Those three places all read Aanmeldingen in Dutch.
- [x] The English menu reads Settings.
- [x] Dutch settings stays Instellingen.
- [x] No new feature is added. Only the strings change.

**Prompt**

```text
Implement the One name section in docs/UX_EASE_OF_USE.md.
Change the English and Dutch ARB files, and any freelancer home or menu widget that hardcodes a different label.
Use one label for the home shortcut, the menu entry, and the My shifts screen title: Applications in English and Aanmeldingen in Dutch.
Change the English settings string from Setting to Settings. Leave the Dutch settings string as Instellingen.
Do not rename routes.
```

### Login role

**Phase 2.** Second prompt in Phase 2.

`WelcomeScreen._goToLogin` in `lib/screen/welcome screen/welcome_screen.dart` always pushes `/auth/seller/login`, including when Employer is selected. `ClientLogIn` and `SellerLogIn` are empty subclasses of `UnifiedLogIn`, and `UnifiedLogIn` always uses orange `kPrimaryColor` with no role chip. Signup already shows the chip and a role color. The signup footer in `lib/screen/widgets/auth/sign_up_screen.dart` pushes a bare `UnifiedLogIn()` with `launch`, so the address stays on the signup route.

**Adjustment.** Pass the role into `UnifiedLogIn`. Employer login is orange with an Employer chip. Freelancer login is cyan (`kSellerPrimary`) with a Freelancer chip. Welcome's "I already have an account" follows the selected card: Employer to `/auth/client/login`, Freelancer to `/auth/seller/login`. The signup "Log in" link uses `context.go` to that role's login route instead of stacking `UnifiedLogIn`.

**Checklist**

- [x] Employer selected, then "I already have an account," opens `/auth/client/login` with an Employer chip and orange actions.
- [x] Freelancer selected, then "I already have an account," opens `/auth/seller/login` with a Freelancer chip and cyan actions.
- [x] Signup "Log in" goes to the matching role login with `context.go` and does not stack another login on the signup route.
- [x] Keyboard Done, autofill, the reset snackbar, and the 44 px save-password target still work on both logins.
- [x] Login API calls are unchanged.

**Prompt**

```text
Implement the Login role section in docs/UX_EASE_OF_USE.md.
Change lib/screen/welcome screen/welcome_screen.dart, lib/screen/widgets/auth/unified_log_in.dart, the client and seller login subclasses, and lib/screen/widgets/auth/sign_up_screen.dart.
Welcome's existing-account button follows the selected role: Employer to /auth/client/login, Freelancer to /auth/seller/login.
Show an Employer or Freelancer chip on login. Employer actions stay orange. Freelancer actions use kSellerPrimary.
Signup's Log in link context.go's to that role's login route instead of pushing UnifiedLogIn.
Keep keyboard Done, autofill, the reset snackbar, and the 44 px save-password target.
Do not change the login API calls.
```

### Empty job text

**Phase 3.** First prompt in Phase 3.

The Find Jobs card in `lib/screen/seller screen/buyer request/seller_buyer_request.dart` always prints `req['description']`. Stored descriptions that are empty or the literal "none" show up under the title as the word "none" (seen on Software Developer).

**Adjustment.** Skip that line when the description is null, blank, or the word "none" ignoring case. Keep a real description, clamped to two lines as it is today.

**Checklist**

- [x] A job whose description is empty, whitespace, or "none" does not show a description line.
- [x] A job with a real description still shows it, at most two lines.
- [x] The title, location, tags, and price still show.

**Prompt**

```text
Implement the Empty job text section in docs/UX_EASE_OF_USE.md.
Change the Find Jobs card in lib/screen/seller screen/buyer request/seller_buyer_request.dart.
Do not render the description line when the value is null, blank, or the word none in any case.
Keep a real description at two lines.
Do not change the title, location, tags, or price.
```

### One bell

**Phase 3.** Second prompt in Phase 3.

`ClientShellAppBar` already puts a notifications bell in the header. Find Jobs adds a second icon, `Icons.notifications_active_outlined`, whose tooltip is `jobAlertsAppBarTooltip` ("Job alerts"). On the screen they look like two of the same bell.

**Adjustment.** Remove the extra bell from the Find Jobs app bar. Keep notifications where the shell bar already puts them. Add a text action labeled with the existing job-alerts string, so opening alerts is still one tap and does not look like a second notification button.

**Checklist**

- [x] Find Jobs shows one bell, and it opens notifications.
- [x] Job alerts stay one tap away, with a visible "Job alerts" label (Dutch: Jobmeldingen).
- [x] The alerts screen itself is unchanged.

**Prompt**

```text
Implement the One bell section in docs/UX_EASE_OF_USE.md.
Change lib/screen/seller screen/buyer request/seller_buyer_request.dart.
Remove the extra notifications_active icon from the Find Jobs app bar.
Keep the shell notifications bell.
Add a text action that opens the existing job alerts screen, labeled with the existing job-alerts string in English and Dutch.
Do not change the alerts screen.
```

### Selected tab

**Phase 3.** Third prompt in Phase 3.

`_ShellBottomNavTile` in `lib/router/app_router.dart` sets `Semantics(selected: i == currentIndex)`. In the running app the accessibility tree still exposed Home, Message, Find Jobs, and Contracts as current at the same time, on both shells. The paint is already correct: only the open tab is colored.

**Adjustment.** Keep a single selected tab in the semantics tree. Unselected tiles must not be exposed as selected or current. Do this for the employer bar (five tabs) and the freelancer bar (four tabs). Do not change routes or labels.

**Checklist**

- [x] On the freelancer shell, only the open tab is selected in the accessibility tree.
- [x] On the employer shell, only the open tab is selected in the accessibility tree.
- [x] The colored tab still matches the open screen.
- [x] Tab routes and labels are unchanged.

**Prompt**

```text
Implement the Selected tab section in docs/UX_EASE_OF_USE.md.
Change lib/router/app_router.dart.
_ShellBottomNavTile already passes Semantics selected for the open index, but the accessibility tree still marks every shell tab as current.
Make unselected tiles not expose selected or current, on both the employer and freelancer bars.
Do not change routes, labels, or which tab is painted as active.
```

### Freelancer home

**Phase 4.** Only prompt in Phase 4.

`seller_home_screen.dart` leads with the job banner and two shortcuts, then `_buildWorkOverviewCard` shows six totals (hours, agreed amount, marked paid, unpaid, completed, active) before the shift list. On a phone the work tracker starts under the tab bar, so the first screen feels cut off. The useful line is already there: the on-site contract banner ("clock in via Attendance") and the next shifts.

**Adjustment.** On the first screen, keep the banner, the shortcuts, the on-site clock-in line, and the shift list. Collapse the six totals behind the work tracker title, one tap to expand. Tapping a total still goes where it goes today (attendance or contracts). Do not remove the numbers.

**Checklist**

- [x] The first screen shows the job banner, shortcuts, the clock-in line, and the shift list without the six totals expanded.
- [x] One tap on the work tracker reveals hours, agreed amount, marked paid, unpaid, completed, and active.
- [x] Those totals still navigate as they do now.
- [x] Employer home is unchanged.

**Prompt**

```text
Implement the Freelancer home section in docs/UX_EASE_OF_USE.md.
Change lib/screen/seller screen/seller home/seller_home_screen.dart.
Keep the job banner, shortcuts, on-site clock-in line, and shift list on the first screen.
Collapse the six work-overview totals behind one tap on the work tracker.
Tapping a revealed total still opens attendance or contracts as it does today.
Do not remove the totals, and do not change the employer home.
```
