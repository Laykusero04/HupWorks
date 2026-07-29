/// In-memory [profiles.role] cache for sync GoRouter redirects.
///
/// Kept separate from [AuthService] / [ProfileService] to avoid circular imports.
class RoleCache {
  RoleCache._();

  static String? _role;
  static String? _userId;

  static String? get role => _role;

  static String? get userId => _userId;

  static void set({required String userId, required String role}) {
    final normalized = role.trim().toLowerCase();
    if (normalized != 'seller' && normalized != 'client') return;
    _userId = userId;
    _role = normalized;
  }

  static void clear() {
    _role = null;
    _userId = null;
  }

  static String? roleForUser(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    if (_userId != userId) return null;
    return _role;
  }
}
