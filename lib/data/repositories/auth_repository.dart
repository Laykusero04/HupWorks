import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../services/auth_service.dart';
import '../models/profile_model.dart';

class AuthRepository {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      return await AuthService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
      );
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await AuthService.signIn(email: email, password: password);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await AuthService.resetPassword(email: email);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await AuthService.signOut();
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  bool get isLoggedIn => AuthService.isLoggedIn;
  User? get currentUser => AuthService.currentUser;

  Future<String?> getUserRole() async {
    try {
      return await AuthService.getUserRole();
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  Future<Profile?> getCurrentProfile() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return null;

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return Profile.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
