import 'package:freelancer/core/auth/app_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Same session key Supabase uses when no custom storage is passed.
String supabaseSessionStorageKey(String supabaseUrl) {
  final projectRef = Uri.parse(supabaseUrl).host.split('.').first;
  return 'sb-$projectRef-auth-token';
}

/// Persists the Supabase session in encrypted storage.
///
/// On first launch after this change, copies the old plaintext session out of
/// SharedPreferences so existing logins stay signed in.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required this.persistSessionKey});

  final String persistSessionKey;

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    await AppSecureStorage.migrateFromPrefs(
      prefs: prefs,
      key: persistSessionKey,
    );
  }

  @override
  Future<bool> hasAccessToken() async {
    final value = await accessToken();
    return value != null && value.isNotEmpty;
  }

  @override
  Future<String?> accessToken() {
    return AppSecureStorage.instance.read(key: persistSessionKey);
  }

  @override
  Future<void> removePersistedSession() {
    return AppSecureStorage.instance.delete(key: persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return AppSecureStorage.instance.write(
      key: persistSessionKey,
      value: persistSessionString,
    );
  }
}

/// Stores the short-lived PKCE code verifier outside plaintext prefs.
class SecurePkceStorage extends GotrueAsyncStorage {
  static const _codeVerifierKey = 'supabase.auth.token-code-verifier';

  bool _migrated = false;

  Future<void> _migrateLegacyVerifier() async {
    if (_migrated) return;
    final prefs = await SharedPreferences.getInstance();
    await AppSecureStorage.migrateFromPrefs(
      prefs: prefs,
      key: _codeVerifierKey,
    );
    _migrated = true;
  }

  @override
  Future<String?> getItem({required String key}) async {
    await _migrateLegacyVerifier();
    return AppSecureStorage.instance.read(key: key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    await _migrateLegacyVerifier();
    await AppSecureStorage.instance.write(key: key, value: value);
  }

  @override
  Future<void> removeItem({required String key}) async {
    await _migrateLegacyVerifier();
    await AppSecureStorage.instance.delete(key: key);
  }
}
