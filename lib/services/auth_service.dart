import 'package:freelancer/core/auth/role_cache.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  /// Must also be listed under Supabase Auth → URL Configuration → Redirect URLs.
  static const passwordResetRedirectTo = 'hupworks://reset-password';

  /// After the user taps the confirm-email link (Confirm email enabled in Auth).
  static const emailConfirmRedirectTo = 'hupworks://confirm-email';

  /// True after [AuthChangeEvent.passwordRecovery] until the new password is saved.
  static bool passwordRecoveryPending = false;

  /// Sign up with email and password.
  /// With "Confirm email" enabled, [AuthResponse.session] is usually null until
  /// the user opens the confirmation link.
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
      emailRedirectTo: emailConfirmRedirectTo,
      data: {
        'name': name,
        'role': role,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    // New session (confirm email off, or already confirmed): ensure profile.
    if (response.session != null) {
      await ensureProfileExists(
        preferredName: name,
        preferredRole: role,
        preferredPhone: phone,
      );
      await getUserRole(forceRefresh: true);
    }
    return response;
  }

  /// Resend the signup confirmation email (Confirm email flow).
  static Future<void> resendSignupConfirmation({required String email}) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: emailConfirmRedirectTo,
    );
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
    await ensureProfileExists();
    await getUserRole(forceRefresh: true);
    return response;
  }

  /// Send password reset email (opens app via [passwordResetRedirectTo]).
  static Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: passwordResetRedirectTo,
    );
  }

  /// Set a new password after opening the recovery link.
  static Future<void> updatePassword({required String password}) async {
    await _client.auth.updateUser(UserAttributes(password: password));
    passwordRecoveryPending = false;
  }

  /// Sign out
  static Future<void> signOut() async {
    ProfileService.clearProfileCache();
    clearRoleCache();
    passwordRecoveryPending = false;
    await _client.auth.signOut();
  }

  /// Check if user is logged in
  static bool get isLoggedIn => _client.auth.currentSession != null;

  /// Get current user
  static User? get currentUser => _client.auth.currentUser;

  /// Sync [profiles.role] for GoRouter redirects (may be null while loading).
  static String? get cachedRole => RoleCache.roleForUser(currentUser?.id);

  /// Sellers who have not finished SetupSellerProfile.
  static bool get needsSellerOnboarding {
    if (cachedRole != 'seller') return false;
    return !RoleCache.sellerOnboardingCompleted;
  }

  static void markSellerOnboardingCompleted() {
    RoleCache.setSellerOnboardingCompleted(true);
  }

  static void clearRoleCache() => RoleCache.clear();

  /// Store a normalized role from [profiles].
  static void setCachedRole(String? role, {bool? sellerOnboardingCompleted}) {
    final user = currentUser;
    if (user == null || role == null) {
      clearRoleCache();
      return;
    }
    RoleCache.set(
      userId: user.id,
      role: role,
      sellerOnboardingCompleted: sellerOnboardingCompleted,
    );
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

    await ensureProfileExists();

    Map<String, dynamic>? data;
    try {
      data = await _client
          .from('profiles')
          .select('role, seller_onboarding_completed')
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      // Column may be missing until migration 0035 is applied.
      data = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
    }

    if (data == null) {
      clearRoleCache();
      return null;
    }

    final role = data['role'] as String?;
    final completed = data['seller_onboarding_completed'] as bool? ??
        (role != 'seller');
    setCachedRole(role, sellerOnboardingCompleted: completed);
    return cachedRole;
  }

  /// Creates [profiles] (+ seller rows) when the DB trigger did not run.
  static Future<void> ensureProfileExists({
    String? preferredName,
    String? preferredRole,
    String? preferredPhone,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;

    final meta = user.userMetadata ?? {};
    var role = (preferredRole ?? meta['role'] as String? ?? 'client')
        .trim()
        .toLowerCase();
    if (role != 'client' && role != 'seller') role = 'client';

    final metaName = (meta['name'] as String?)?.trim() ?? '';
    final preferred = preferredName?.trim() ?? '';
    final name = preferred.isNotEmpty
        ? preferred
        : (metaName.isNotEmpty
            ? metaName
            : (user.email?.split('@').first ?? 'User'));

    final phoneRaw = preferredPhone ?? meta['phone'] as String?;
    final phone = phoneRaw?.trim();

    try {
      await _client.from('profiles').insert({
        'id': user.id,
        'role': role,
        'name': name,
        'email': user.email ?? '',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'seller_onboarding_completed': role != 'seller',
      });
    } catch (_) {
      // Race with DB trigger — profile may already exist.
      return;
    }

    if (role == 'seller') {
      try {
        await _client.from('seller_profiles').insert({'user_id': user.id});
      } catch (_) {}
      try {
        await _client.from('seller_private_details').insert({'user_id': user.id});
      } catch (_) {}
    }
  }

  /// Persist seller onboarding complete and update cache.
  static Future<void> completeSellerOnboarding() async {
    final user = currentUser;
    if (user == null) throw Exception('Not logged in');
    await _client.from('profiles').update({
      'seller_onboarding_completed': true,
    }).eq('id', user.id);
    // Always set seller + completed so Done → home works even if cache was empty.
    setCachedRole('seller', sellerOnboardingCompleted: true);
    ProfileService.clearProfileCache();
  }

  /// Home path for the current cached/DB role.
  static String homePathForRole(String? role) {
    if (role == 'seller' && needsSellerOnboarding) {
      return AppRoutes.sellerSetupProfile;
    }
    return role == 'seller' ? '/seller' : '/client';
  }
}
