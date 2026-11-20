import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/services/user_private_details_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Decides whether the signed-in user is sent to the first-sign-in personal
/// details screen (T-0172). The router reads [needsPrompt] synchronously; it
/// is filled by [refresh] right after sign-in.
///
/// The step is skippable. Skip is remembered per user on this device (the
/// consent version that was skipped, no field values) so nobody is nagged. It is
/// version-aware: when [AppInfo.privacyConsentVersion] changes, a user who
/// skipped is prompted once more. Otherwise the user is asked again only from
/// the "Personal details" trust item or the profile edit section.
class PersonalDetailsGate {
  PersonalDetailsGate._();

  static const _skipPrefix = 'private_details_skip_version_';

  /// Longest the gate may hold the router back on a slow network. On timeout
  /// the user is simply not prompted this time.
  static Duration refreshTimeout = const Duration(seconds: 5);

  /// Test hook: replaces the network/prefs load (for example a hanging one).
  static Future<void> Function(String uid, String? email)? loadOverride;

  static String? _userId;
  static bool _needsPrompt = false;

  /// True once the first-sign-in screen should be shown for the current user.
  static bool get needsPrompt => _needsPrompt;

  static String _key(String uid) => '$_skipPrefix$uid';

  /// Loads the state for the current user. Never throws; on any failure the
  /// user is simply not prompted (the trust item still offers the step).
  static Future<void> refresh() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      reset();
      return;
    }
    try {
      await (loadOverride ?? _load)(user.id, user.email)
          .timeout(refreshTimeout);
    } catch (_) {
      // Timeout or any failure: do not prompt, never block the router.
      _userId = user.id;
      _needsPrompt = false;
    }
  }

  static Future<void> _load(String uid, String? email) async {
    await PendingSignupDob.flushFor(email);
    final skippedVersion =
        (await SharedPreferences.getInstance()).getString(_key(uid));
    final row = await UserPrivateDetailsService.getMine();
    final done = row != null &&
        row.consentVersion == AppInfo.privacyConsentVersion &&
        row.hasConsent;
    final skipped = skippedVersion == AppInfo.privacyConsentVersion;
    _userId = uid;
    _needsPrompt = !done && !skipped;
  }

  /// The user tapped "Skip for now": remember it for this user on this device.
  static Future<void> markSkipped() async {
    final uid = _userId ?? Supabase.instance.client.auth.currentUser?.id;
    _needsPrompt = false;
    if (uid == null) return;
    try {
      await (await SharedPreferences.getInstance())
          .setString(_key(uid), AppInfo.privacyConsentVersion);
    } catch (_) {}
  }

  /// Consent and details were saved.
  static void markSaved() => _needsPrompt = false;

  /// Signed out.
  static void reset() {
    _userId = null;
    _needsPrompt = false;
  }
}

/// Date of birth typed at signup, held in memory until the account has a
/// session (email confirmation may delay it), then written to the private
/// table. Held together with the email so it can never land on another user.
/// Nothing is written to disk.
class PendingSignupDob {
  PendingSignupDob._();

  static DateTime? _dob;
  static String? _email;

  static bool get hasPending => _dob != null;

  static void hold(String email, DateTime dob) {
    _email = email.trim().toLowerCase();
    _dob = dob;
  }

  static void clear() {
    _dob = null;
    _email = null;
  }

  /// Stores the held date for the signed-in user when the email matches and
  /// no date of birth is stored yet (it never overwrites an existing one, so a
  /// date typed for an already-registered email cannot replace the owner's).
  /// Returns true if it was stored. Keeps the value on failure so the next
  /// sign-in can retry; a failed store never blocks the user.
  static Future<bool> flushFor(String? signedInEmail) async {
    final dob = _dob;
    if (dob == null) return false;
    if (signedInEmail == null || signedInEmail.trim().toLowerCase() != _email) {
      return false;
    }
    try {
      final existing = await UserPrivateDetailsService.getMine();
      if (existing?.dateOfBirth != null) {
        clear();
        return false;
      }
      await UserPrivateDetailsService.upsertMine(dateOfBirth: dob);
      clear();
      return true;
    } catch (_) {
      return false;
    }
  }
}
