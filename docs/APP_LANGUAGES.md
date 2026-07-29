# App languages (i18n)

HupWorks uses Flutter **gen-l10n** for UI language.  
**Default language is English (`en`).**

## Supported locales

| Code | Language | Region note | ARB file |
|------|----------|-------------|----------|
| `en` | English | **Default** | `lib/l10n/app_en.arb` |
| `nl` | Dutch (Nederlands) | Netherlands | `lib/l10n/app_nl.arb` |
| `bn` | Bengali | — | `lib/l10n/app_bn.arb` |

Users pick a language in **Settings → Language**. The choice is stored in `SharedPreferences` under `app_locale_code` and restored on next launch. If nothing is stored, the app uses **English**.

> Profile “spoken language” fields (e.g. seller languages on a profile) are **not** the same as app UI locale. Those stay separate.

## How it works

| Piece | Path / role |
|-------|-------------|
| Config | `l10n.yaml`, `pubspec.yaml` (`generate: true`, `flutter_localizations`) |
| Strings | `lib/l10n/app_*.arb` |
| Generated | `lib/l10n/app_localizations*.dart` (via `flutter gen-l10n`) |
| Controller | `lib/core/locale/locale_controller.dart` |
| Scope | `lib/core/locale/locale_scope.dart` |
| App wiring | `lib/main.dart` + `lib/app.dart` (`locale`, `localizationsDelegates`, `onGenerateTitle`) |
| Settings UI | `lib/screen/widgets/language_settings_screen.dart` |
| Helper | `context.l10n` from `lib/l10n/l10n.dart` |
| Enum labels | `lib/l10n/l10n_labels.dart`, `OrderCancellationReason` / `AttendanceMode` with optional `AppLocalizations` |

## Using a string in UI

```dart
import 'package:freelancer/l10n/l10n.dart';

Text(context.l10n.settings);
Text(context.l10n.noSearchResults(query));
Text(context.l10n.errorWithDetail('$e'));
```

## Conventions

1. Add keys to `app_en.arb`, then mirror in `app_nl.arb` and `app_bn.arb`.
2. Run `flutter gen-l10n` (or `flutter pub get`).
3. Prefer ICU placeholders (`sayHelloTo`, `errorWithDetail`) over string concatenation.
4. Reuse common keys (`cancel`, `save`, `retry`, `errorGeneric`) before adding new ones.
5. Store stable English codes in the API where needed (e.g. report reasons via `L10nLabels.reportCodes`); localize display only.

## Do not localize

- Chat **protocol** tokens parsed as structure (e.g. wire text starting with `New bid for`).
- Raw Supabase exception text in logs — show `errorGeneric` / `errorWithDetail` to users and log with `AppLogger`.
- Profile skill-language picker values (user-spoken languages).

## Migration wave checklist

| Wave | Scope | Status |
|------|--------|--------|
| 0 | Shared ARB keys, `L10nLabels`, legal/privacy ARB, settings push, cancellation/attendance/report wiring | Done |
| 1 | Welcome, auth_ui, login/signup/forgot/OTP, create/setup profile | Done |
| 2 | Client/seller home, shell nav, categories/talent, notifications | Done |
| 3 | Jobs, contracts, orders, applications, buyer requests | Done |
| 4 | Attendance screens, hire onboarding, `attendance_format` | Done |
| 5 | Chat list/inbox UI (protocol tokens unchanged) | Done |
| 6 | Profiles, public profiles, favourites, reviews, map picker | Done |
| 7 | Popups, support chat, money UI labels | Done |
| 8 | `onGenerateTitle`, iOS `CFBundleLocalizations`, Android `locales_config` | Done |

## Adding a new language

1. Create `lib/l10n/app_<code>.arb` (copy `app_en.arb`, set `"@@locale": "<code>"`, translate values).
2. Add the display name key to **all** ARB files (e.g. `languageFrench`).
3. Add `Locale('<code>')` to `LocaleController.supportedLocales`.
4. Add a row in `LanguageSettingsScreen` `_options`.
5. Extend `LocaleController.displayName` for the settings trailing label.
6. Add the locale to iOS `CFBundleLocalizations` and Android `locales_config.xml`.
7. Run `flutter gen-l10n` and smoke-test.

## Regenerating after ARB edits

```bash
flutter gen-l10n
# or simply
flutter pub get
```

## Platform notes

- **iOS** system permission strings (camera, location) in `Info.plist` remain English unless localized via `InfoPlist.strings` per locale (optional follow-up).
- **Android** `localeConfig` declares store-visible locales; in-app locale still driven by `LocaleController`.

## Related

- Feature plan: `docs/FEATURE_HARDENING_PHASES.md` (Phase 6)
