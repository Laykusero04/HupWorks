import 'dart:io';

import 'package:freelancer/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Seller verification — profile photo and face+ID are reviewed separately.
class VerificationService {
  static final _client = Supabase.instance.client;
  static const bucket = 'identity-docs';
  static const objectName = 'id_selfie.jpg';

  static String? get _userId => _client.auth.currentUser?.id;

  static String storagePathFor(String userId) => '$userId/$objectName';

  /// Upload ID+face selfie and mark identity verification as pending.
  static Future<void> submitIdSelfie(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final path = storagePathFor(user.id);

    try {
      await _client.storage.from(bucket).upload(
        path,
        imageFile,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Bucket not found') ||
          msg.contains('row-level security') ||
          msg.contains('Unauthorized') ||
          msg.contains('403') ||
          msg.contains('not found')) {
        throw Exception(
          'ID selfie upload blocked by Supabase. Open SQL Editor and run '
          'migrations/0034_seller_identity_verification.sql '
          '(creates the private identity-docs bucket), then try again.',
        );
      }
      rethrow;
    }

    await _client.from('seller_identity_verifications').upsert({
      'user_id': user.id,
      'id_selfie_path': path,
      'status': 'pending',
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_at': null,
      'rejection_reason': null,
    });

    // Trigger syncs profiles.verification_status; also set cache-friendly update.
    await _client.from('profiles').update({
      'verification_status': 'pending',
      'verification_reviewed_at': null,
      'verification_rejection_reason': null,
    }).eq('id', user.id);

    ProfileService.clearProfileCache();
  }

  static Future<Map<String, dynamic>?> getOwnVerification() async {
    final id = _userId;
    if (id == null) return null;
    return await _client
        .from('seller_identity_verifications')
        .select()
        .eq('user_id', id)
        .maybeSingle();
  }

  /// Signed URL for the seller to preview their own submitted selfie.
  static Future<String?> createOwnSelfieSignedUrl({
    int expiresInSeconds = 3600,
  }) async {
    final id = _userId;
    if (id == null) return null;
    final path = storagePathFor(id);
    return await _client.storage.from(bucket).createSignedUrl(
          path,
          expiresInSeconds,
        );
  }

  static String _normalize(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return 'unverified';
    return s;
  }

  /// Face + ID status (legacy field name on profiles).
  static String identityStatusFromProfile(Map<String, dynamic>? profile) =>
      _normalize(profile?['verification_status'] as String?);

  static String profilePhotoStatusFromProfile(Map<String, dynamic>? profile) =>
      _normalize(profile?['profile_photo_status'] as String?);

  /// Combined badge status for UI chips.
  static String statusFromProfile(Map<String, dynamic>? profile) {
    final photo = profilePhotoStatusFromProfile(profile);
    final identity = identityStatusFromProfile(profile);
    if (photo == 'verified' && identity == 'verified') return 'verified';
    if (photo == 'rejected' || identity == 'rejected') return 'rejected';
    if (photo == 'pending' || identity == 'pending') return 'pending';
    return 'unverified';
  }

  /// Sellers may replace the selfie anytime; upload always returns status to pending.
  static bool canResubmit(String status) =>
      status == 'unverified' ||
      status == 'rejected' ||
      status == 'pending' ||
      status == 'verified';

  static VerificationScore scoreFromStatus(String status) =>
      VerificationScore.fromLegacyStatus(status);

  static VerificationScore scoreFromProfile(Map<String, dynamic>? profile) =>
      VerificationScore.fromProfile(profile);
}

/// 100-point verification score — 50 profile photo + 50 face+ID (each after admin accept).
class VerificationScore {
  const VerificationScore({
    required this.profilePhotoStatus,
    required this.identityStatus,
    required this.hasProfilePhoto,
    required this.hasIdSelfie,
    required this.profilePhotoAccepted,
    required this.identityAccepted,
  });

  static const maxScore = 100;
  static const profilePhotoPoints = 50;
  static const identityPoints = 50;

  /// Back-compat aliases used by older widgets.
  static const idSelfiePoints = identityPoints;
  static const adminAcceptedPoints = profilePhotoPoints;

  final String profilePhotoStatus;
  final String identityStatus;
  final bool hasProfilePhoto;
  final bool hasIdSelfie;
  final bool profilePhotoAccepted;
  final bool identityAccepted;

  /// Combined status for badges.
  String get status {
    if (profilePhotoAccepted && identityAccepted) return 'verified';
    if (profilePhotoStatus == 'rejected' || identityStatus == 'rejected') {
      return 'rejected';
    }
    if (profilePhotoStatus == 'pending' || identityStatus == 'pending') {
      return 'pending';
    }
    return 'unverified';
  }

  /// True when either track still needs admin action.
  bool get adminAccepted => profilePhotoAccepted && identityAccepted;

  factory VerificationScore.fromProfile(Map<String, dynamic>? profile) {
    final photoStatus = VerificationService.profilePhotoStatusFromProfile(profile);
    final identityStatus = VerificationService.identityStatusFromProfile(profile);
    final hasPhoto =
        (profile?['profile_image_url'] as String?)?.trim().isNotEmpty == true ||
            photoStatus == 'pending' ||
            photoStatus == 'verified' ||
            photoStatus == 'rejected';
    final hasId = identityStatus == 'pending' ||
        identityStatus == 'verified' ||
        identityStatus == 'rejected';
    return VerificationScore(
      profilePhotoStatus: photoStatus,
      identityStatus: identityStatus,
      hasProfilePhoto: hasPhoto,
      hasIdSelfie: hasId,
      profilePhotoAccepted: photoStatus == 'verified',
      identityAccepted: identityStatus == 'verified',
    );
  }

  /// Fallback when only a single legacy status string is available.
  factory VerificationScore.fromLegacyStatus(String status) {
    final normalized = status.trim().isEmpty ? 'unverified' : status.trim();
    final hasId = normalized == 'pending' ||
        normalized == 'verified' ||
        normalized == 'rejected';
    final accepted = normalized == 'verified';
    return VerificationScore(
      profilePhotoStatus: accepted ? 'verified' : 'unverified',
      identityStatus: normalized,
      hasProfilePhoto: accepted,
      hasIdSelfie: hasId,
      profilePhotoAccepted: accepted,
      identityAccepted: accepted,
    );
  }

  factory VerificationScore.fromStatus(String status) =>
      VerificationScore.fromLegacyStatus(status);

  int get profilePhotoPointsEarned =>
      profilePhotoAccepted ? profilePhotoPoints : 0;
  int get identityPointsEarned => identityAccepted ? identityPoints : 0;

  /// Back-compat getters for older score card code paths.
  int get idPointsEarned => identityPointsEarned;
  int get adminPointsEarned => profilePhotoPointsEarned;

  int get total => profilePhotoPointsEarned + identityPointsEarned;
  double get progress => total / maxScore;
  bool get isComplete => total >= maxScore;
}
