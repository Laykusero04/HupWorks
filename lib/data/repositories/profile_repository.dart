import 'dart:io';

import '../../core/errors/failures.dart';
import '../../services/profile_service.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  Future<Profile?> getProfile() async {
    try {
      final data = await ProfileService.getProfile();
      if (data == null) return null;
      return Profile.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      await ProfileService.updateProfile(updates);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      return await ProfileService.uploadProfileImage(imageFile);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
