import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Soft completeness checks for employer (client) profiles.
///
/// Sellers remain hard-gated via [AuthService.needsSellerOnboarding].
class ClientProfileCompleteness {
  ClientProfileCompleteness._();

  static const _dismissPrefsPrefix = 'client_profile_nudge_dismissed_';

  /// True when photo, phone, or city is missing.
  static bool isIncomplete(Map<String, dynamic>? profile) {
    if (profile == null) return true;
    final photo = ProfileImage.normalize(profile['profile_image_url'] as String?);
    final phone = (profile['phone'] as String?)?.trim() ?? '';
    final city = (profile['city'] as String?)?.trim() ?? '';
    return photo == null || phone.isEmpty || city.isEmpty;
  }

  static String? _userId() => AuthService.currentUser?.id;

  static Future<bool> isNudgeDismissed() async {
    final id = _userId();
    if (id == null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_dismissPrefsPrefix$id') ?? false;
  }

  static Future<void> dismissNudge() async {
    final id = _userId();
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_dismissPrefsPrefix$id', true);
  }

  static Future<void> clearNudgeDismissed() async {
    final id = _userId();
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_dismissPrefsPrefix$id');
  }
}
