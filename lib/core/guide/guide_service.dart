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
