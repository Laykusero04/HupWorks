import 'package:supabase_flutter/supabase_flutter.dart';

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
    return response;
  }

  /// Send password reset email
  static Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Check if user is logged in
  static bool get isLoggedIn => _client.auth.currentSession != null;

  /// Get current user
  static User? get currentUser => _client.auth.currentUser;

  /// Get user role from profile
  static Future<String?> getUserRole() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    return data['role'] as String?;
  }
}
