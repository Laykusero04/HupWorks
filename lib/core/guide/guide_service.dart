import 'package:shared_preferences/shared_preferences.dart';

/// Show-once flags for per-screen guides.
///
/// Key: `guide_seen_<uid>_<role>_<screenId>_v<version>` (bool).
/// Follows the pattern of OnboardingPrefs but async-only (spike: no sync cache).
class GuideService {
  GuideService._();

  static const _prefix = 'guide_seen_';

  static String _key(String uid, String role, String screenId, int version) =>
      '$_prefix${uid}_${role}_${screenId}_v$version';

  static Future<bool> hasSeen({
    required String uid,
    required String role,
    required String screenId,
    required int version,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(uid, role, screenId, version)) ?? false;
  }

  static Future<void> markSeen({
    required String uid,
    required String role,
    required String screenId,
    required int version,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(uid, role, screenId, version), true);
  }

  static String _hintKey(String uid, String role) => 'guide_hint_${uid}_$role';

  /// One-time "tap the (i)" snackbar: shown flag, global per user and role.
  static Future<bool> hasShownInfoHint({
    required String uid,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hintKey(uid, role)) ?? false;
  }

  static Future<void> markInfoHintShown({
    required String uid,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hintKey(uid, role), true);
  }

  /// Clears the seen flag of ONE screen (all versions) for this user and role.
  static Future<void> reset({
    required String uid,
    required String role,
    required String screenId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '$_prefix${uid}_${role}_${screenId}_v';
    for (final k in prefs.getKeys().where((k) => k.startsWith(prefix))) {
      await prefs.remove(k);
    }
  }

  /// Removes every guide flag for this user and role (replay / debug reset).
  static Future<void> resetAll({
    required String uid,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final marker = '$_prefix${uid}_${role}_';
    for (final k in prefs.getKeys().where((k) => k.startsWith(marker))) {
      await prefs.remove(k);
    }
  }
}
