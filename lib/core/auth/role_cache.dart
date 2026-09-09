/// In-memory [profiles.role] (+ seller onboarding) cache for sync GoRouter redirects.
///
/// Kept separate from [AuthService] / [ProfileService] to avoid circular imports.
class RoleCache {
  RoleCache._();

  static String? _role;
  static String? _userId;
  static bool _sellerOnboardingCompleted = true;

  static String? get role => _role;

  static String? get userId => _userId;

  /// Sellers only: false until SetupSellerProfile finishes.
  static bool get sellerOnboardingCompleted => _sellerOnboardingCompleted;

  static void set({
    required String userId,
    required String role,
    bool? sellerOnboardingCompleted,
  }) {
    final normalized = role.trim().toLowerCase();
    if (normalized != 'seller' && normalized != 'client') return;
    final sameUser = _userId == userId;
    _userId = userId;
    _role = normalized;
    if (normalized == 'seller') {
      if (sellerOnboardingCompleted != null) {
        _sellerOnboardingCompleted = sellerOnboardingCompleted;
      } else if (!sameUser) {
        // Unknown seller — treat as incomplete until AuthService loads the flag.
        // Same user with omitted flag: preserve cached value (do not wipe).
        _sellerOnboardingCompleted = false;
      }
    } else {
      _sellerOnboardingCompleted = true;
    }
  }

  static void setSellerOnboardingCompleted(bool completed) {
    if (_role != 'seller') return;
    _sellerOnboardingCompleted = completed;
  }

  static void clear() {
    _role = null;
    _userId = null;
    _sellerOnboardingCompleted = true;
  }

  static String? roleForUser(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    if (_userId != userId) return null;
    return _role;
  }
}
