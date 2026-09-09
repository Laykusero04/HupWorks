import 'dart:io';

import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/verification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Employer (client) verification — profile photo + optional personal ID or company doc.
class EmployerVerificationService {
  static final _client = Supabase.instance.client;
  static const bucket = 'identity-docs';
  static const idObjectName = 'id_selfie.jpg';
  static const companyObjectName = 'company_doc.jpg';

  static const verifyTypePersonalId = 'personal_id';
  static const verifyTypeCompany = 'company';

  static String? get _userId => _client.auth.currentUser?.id;

  static String idStoragePathFor(String userId) => '$userId/$idObjectName';
  static String companyStoragePathFor(String userId) =>
      '$userId/$companyObjectName';

  static Future<void> submitPersonalId(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final path = idStoragePathFor(user.id);
    await _upload(path, imageFile);

    await _client.from('employer_verifications').upsert({
      'user_id': user.id,
      'verify_type': verifyTypePersonalId,
      'id_selfie_path': path,
      'company_doc_path': null,
      'status': 'pending',
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_at': null,
      'rejection_reason': null,
    });

    await _markProfilePending(user.id);
  }

  static Future<void> submitCompanyDoc({
    required File imageFile,
    required String companyName,
    String? registrationNumber,
    String? website,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final name = companyName.trim();
    if (name.isEmpty) throw Exception('Company name is required');

    final path = companyStoragePathFor(user.id);
    await _upload(path, imageFile);

    final reg = registrationNumber?.trim();
    final web = website?.trim();

    await _client.from('employer_verifications').upsert({
      'user_id': user.id,
      'verify_type': verifyTypeCompany,
      'company_doc_path': path,
      'id_selfie_path': null,
      'company_name': name,
      'company_registration_number':
          (reg == null || reg.isEmpty) ? null : reg,
      'company_website': (web == null || web.isEmpty) ? null : web,
      'status': 'pending',
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_at': null,
      'rejection_reason': null,
    });

    await _client.from('profiles').update({
      'company_name': name,
      if (reg != null && reg.isNotEmpty) 'company_registration_number': reg,
      if (web != null && web.isNotEmpty) 'company_website': web,
      'verification_status': 'pending',
      'verification_reviewed_at': null,
      'verification_rejection_reason': null,
    }).eq('id', user.id);

    ProfileService.clearProfileCache();
  }

  static Future<void> _upload(String path, File imageFile) async {
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
          'Document upload blocked by Supabase. Open SQL Editor and run '
          'migrations/0034_seller_identity_verification.sql and '
          'migrations/0043_employer_verification.sql, then try again.',
        );
      }
      rethrow;
    }
  }

  static Future<void> _markProfilePending(String userId) async {
    await _client.from('profiles').update({
      'verification_status': 'pending',
      'verification_reviewed_at': null,
      'verification_rejection_reason': null,
    }).eq('id', userId);
    ProfileService.clearProfileCache();
  }

  static Future<Map<String, dynamic>?> getOwnVerification() async {
    final id = _userId;
    if (id == null) return null;
    return await _client
        .from('employer_verifications')
        .select()
        .eq('user_id', id)
        .maybeSingle();
  }

  static Future<String?> createOwnDocSignedUrl({
    int expiresInSeconds = 3600,
  }) async {
    final id = _userId;
    if (id == null) return null;
    final row = await getOwnVerification();
    if (row == null) return null;
    final type = row['verify_type'] as String?;
    final path = type == verifyTypeCompany
        ? (row['company_doc_path'] as String? ?? companyStoragePathFor(id))
        : (row['id_selfie_path'] as String? ?? idStoragePathFor(id));
    return await _client.storage
        .from(bucket)
        .createSignedUrl(path, expiresInSeconds);
  }

  /// Combined badge status (photo + upgrade track).
  static String statusFromProfile(Map<String, dynamic>? profile) =>
      VerificationService.statusFromProfile(profile);

  static VerificationScore scoreFromProfile(Map<String, dynamic>? profile) =>
      VerificationScore.fromProfile(profile);

  static bool isFullyVerified(Map<String, dynamic>? profile) =>
      scoreFromProfile(profile).isComplete;
}
