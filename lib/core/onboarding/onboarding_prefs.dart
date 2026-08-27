import 'package:shared_preferences/shared_preferences.dart';

/// Sync cache of the first-run product onboarding flag for GoRouter redirects.
class OnboardingPrefs {
  OnboardingPrefs._();

  static const prefsKey = 'has_seen_onboarding';

  static bool _hasSeen = false;
  static bool _loaded = false;

  static bool get hasSeen => _hasSeen;

  static bool get isLoaded => _loaded;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeen = prefs.getBool(prefsKey) ?? false;
    _loaded = true;
  }

  static Future<void> markSeen() async {
    _hasSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }
}
