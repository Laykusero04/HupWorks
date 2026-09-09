import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Employer profile gate before posting jobs (Option C).
///
/// Requires photo, phone, city, and company/about bio.
/// Sellers remain hard-gated via [AuthService.needsSellerOnboarding].
class ClientProfileCompleteness {
  ClientProfileCompleteness._();

  static const _dismissPrefsPrefix = 'client_profile_nudge_dismissed_';

  /// Soft home nudge — photo, phone, or city missing.
  static bool isIncomplete(Map<String, dynamic>? profile) {
    if (profile == null) return true;
    final photo = ProfileImage.normalize(profile['profile_image_url'] as String?);
    final phone = (profile['phone'] as String?)?.trim() ?? '';
    final city = (profile['city'] as String?)?.trim() ?? '';
    return photo == null || phone.isEmpty || city.isEmpty;
  }

  /// Hard gate before creating a job post.
  static bool canPostJobs(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    final photo = ProfileImage.normalize(profile['profile_image_url'] as String?);
    final phone = (profile['phone'] as String?)?.trim() ?? '';
    final city = (profile['city'] as String?)?.trim() ?? '';
    final bio = (profile['bio'] as String?)?.trim() ?? '';
    return photo != null && phone.isNotEmpty && city.isNotEmpty && bio.isNotEmpty;
  }

  /// Missing fields for gate UI copy.
  static List<String> missingForJobPost(Map<String, dynamic>? profile) {
    if (profile == null) {
      return ['photo', 'phone', 'city', 'bio'];
    }
    final missing = <String>[];
    if (ProfileImage.normalize(profile['profile_image_url'] as String?) == null) {
      missing.add('photo');
    }
    if (((profile['phone'] as String?)?.trim() ?? '').isEmpty) {
      missing.add('phone');
    }
    if (((profile['city'] as String?)?.trim() ?? '').isEmpty) {
      missing.add('city');
    }
    if (((profile['bio'] as String?)?.trim() ?? '').isEmpty) {
      missing.add('bio');
    }
    return missing;
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
