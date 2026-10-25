import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encrypted keystore / keychain storage for auth secrets.
class AppSecureStorage {
  AppSecureStorage._();

  static const instance = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Moves a plaintext [SharedPreferences] value into secure storage, then deletes it.
  ///
  /// If a secure value already exists it is kept. The plaintext copy is removed
  /// only after a successful write, so a failed migration can retry next launch.
  static Future<void> migrateFromPrefs({
    required SharedPreferences prefs,
    required String key,
  }) async {
    if (!prefs.containsKey(key)) return;
    final value = prefs.getString(key);
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
      return;
    }
    final existing = await instance.read(key: key);
    if (existing == null || existing.isEmpty) {
      await instance.write(key: key, value: value);
    }
    await prefs.remove(key);
  }
}
