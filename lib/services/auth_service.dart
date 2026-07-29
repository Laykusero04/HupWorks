import 'package:freelancer/core/auth/role_cache.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role,
        'phone': phone,
      },
    );
    return response;
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Prefer DB role over JWT metadata (can drift for older accounts).
    await getUserRole(forceRefresh: true);
    return response;
  }

  /// Send password reset email
  static Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Sign out
  static Future<void> signOut() async {
    ProfileService.clearProfileCache();
    clearRoleCache();
    await _client.auth.signOut();
  }

  /// Check if user is logged in
  static bool get isLoggedIn => _client.auth.currentSession != null;

  /// Get current user
  static User? get currentUser => _client.auth.currentUser;

  /// Sync [profiles.role] for GoRouter redirects (may be null while loading).
  static String? get cachedRole => RoleCache.roleForUser(currentUser?.id);

  static void clearRoleCache() => RoleCache.clear();

  /// Store a normalized role from [profiles].
  static void setCachedRole(String? role) {
    final user = currentUser;
    if (user == null || role == null) {
      clearRoleCache();
      return;
    }
    RoleCache.set(userId: user.id, role: role);
  }

  /// Get user role from [profiles.role] (source of truth). Caches for sync routing.
  static Future<String?> getUserRole({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) {
      clearRoleCache();
      return null;
    }

    if (!forceRefresh && cachedRole != null) {
      return cachedRole;
    }

    final data = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    setCachedRole(data['role'] as String?);
    return cachedRole;
  }

  /// Home path for the current cached/DB role.
  static String homePathForRole(String? role) {
    return role == 'seller' ? '/seller' : '/client';
  }
}
