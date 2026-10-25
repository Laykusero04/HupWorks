import 'package:freelancer/core/auth/app_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local "Save Password" for the login screen.
///
/// The email stays in SharedPreferences. The password is encrypted and any
/// older plaintext copy is deleted on the next read or save.
class LoginCredentialsPrefs {
  LoginCredentialsPrefs._();

  static const _rememberKey = 'login_remember_password';
  static const _emailKey = 'login_saved_email';
  static const _passwordKey = 'login_saved_password';

  static Future<({bool remember, String email, String password})> load() async {
    final prefs = await SharedPreferences.getInstance();
    await AppSecureStorage.migrateFromPrefs(prefs: prefs, key: _passwordKey);

    final remember = prefs.getBool(_rememberKey) ?? false;
    if (!remember) {
      return (remember: false, email: '', password: '');
    }
    return (
      remember: true,
      email: prefs.getString(_emailKey) ?? '',
      password: await AppSecureStorage.instance.read(key: _passwordKey) ?? '',
    );
  }

  static Future<void> save({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, true);
    await prefs.setString(_emailKey, email);
    await prefs.remove(_passwordKey);
    await AppSecureStorage.instance.write(key: _passwordKey, value: password);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
    await AppSecureStorage.instance.delete(key: _passwordKey);
  }
}
