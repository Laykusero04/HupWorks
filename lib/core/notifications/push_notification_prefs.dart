import 'package:shared_preferences/shared_preferences.dart';

/// User preference for OS tray / local push-style notifications.
///
/// In-app banners while the app is open are unaffected.
class PushNotificationPrefs {
  PushNotificationPrefs._();

  static const prefsKey = 'push_notifications_enabled';

  /// Default on — matches existing LocalNotificationService behavior.
  static bool _cached = true;
  static bool _loaded = false;

  static bool get enabled => _cached;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getBool(prefsKey) ?? true;
    _loaded = true;
  }

  static Future<bool> isEnabled() async {
    if (!_loaded) await load();
    return _cached;
  }

  static Future<void> setEnabled(bool value) async {
    _cached = value;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, value);
  }
}
