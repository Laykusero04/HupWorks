import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/core/constants/text_styles.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Shared pick → crop (drag/zoom) → optional upload for profile avatars.
class ProfileAvatarPicker {
  ProfileAvatarPicker._();

  /// Shows gallery/camera dialog, then opens the circular crop UI.
  /// Returns a local cropped file, or null if cancelled.
  static Future<File?> pickAndCrop(BuildContext context) async {
    final source = await _showSourceDialog(context);
    if (source == null || !context.mounted) return null;
    return pickFromSourceAndCrop(context, source);
  }

  /// Pick from [source], then crop. Returns null if cancelled.
  static Future<File?> pickFromSourceAndCrop(
    BuildContext context,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 95,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked == null || !context.mounted) return null;
    return cropAvatar(context, picked.path);
  }

  /// Opens crop UI (drag / zoom / rotate) with a locked circular 1:1 frame.
  /// If the cropper fails to open, falls back to the original image.
  static Future<File?> cropAvatar(BuildContext context, String sourcePath) async {
    final l10n = context.l10n;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: 1024,
        maxHeight: 1024,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: l10n.selectProfileImage,
            toolbarColor: kPrimaryColor,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: kPrimaryColor,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            cropStyle: CropStyle.circle,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: l10n.selectProfileImage,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            cropStyle: CropStyle.circle,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
        ],
      );
      if (cropped == null) return null;
      return File(cropped.path);
    } catch (_) {
      // Crop UI unavailable on this device — still allow setting a photo.
      final original = File(sourcePath);
      if (await original.exists()) return original;
      return null;
    }
  }

  /// Pick image without circular avatar crop (e.g. ID + face selfie).
  static Future<File?> pickImage(BuildContext context) async {
    final source = await _showSourceDialog(context);
    if (source == null || !context.mounted) return null;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Full pipeline: pick → crop → upload to Supabase `avatars` bucket.
  /// Returns the new public URL, or null if cancelled.
  static Future<String?> pickCropAndUpload(BuildContext context) async {
    final file = await pickAndCrop(context);
    if (file == null) return null;
    try {
      return await ProfileService.uploadProfileImage(file);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('row-level security') ||
          msg.contains('Unauthorized') ||
          msg.contains('403') ||
          msg.contains('Bucket not found') ||
          msg.contains('not found')) {
        throw Exception(
          'Could not upload photo. In Supabase, run migrations/0033_avatars_storage.sql '
          'so the public avatars bucket policies allow your account to upload.',
        );
      }
      rethrow;
    }
  }

  static Future<ImageSource?> _showSourceDialog(BuildContext context) {
    final l10n = context.l10n;
    return showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectProfileImage,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          Navigator.pop(dialogContext, ImageSource.gallery),
                      child: Column(
                        children: [
                          Icon(Icons.photo_library, color: kPrimaryColor, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            l10n.photoGallery,
                            style: kTextStyle.copyWith(color: kPrimaryColor),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pop(dialogContext, ImageSource.camera),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.photo_camera,
                            color: kLightNeutralColor,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.takePhoto,
                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
