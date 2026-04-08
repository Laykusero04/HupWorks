import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final _client = Supabase.instance.client;

  /// Fetch current user's profile
  static Future<Map<String, dynamic>?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return data;
  }

  /// Update profile fields
  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('profiles').update(updates).eq('id', user.id);
  }

  /// Upload profile image and update profile_image_url
  static Future<String> uploadProfileImage(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final ext = imageFile.path.split('.').last;
    final path = '${user.id}/avatar.$ext';

    await _client.storage.from('avatars').upload(
      path,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );

    final imageUrl = _client.storage.from('avatars').getPublicUrl(path);

    await _client.from('profiles').update({
      'profile_image_url': imageUrl,
    }).eq('id', user.id);

    return imageUrl;
  }
}
