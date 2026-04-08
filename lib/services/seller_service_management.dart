import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerServiceManagement {
  static final _client = Supabase.instance.client;

  /// Fetch all services for the current seller
  static Future<List<Map<String, dynamic>>> getMyServices() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('services')
        .select()
        .eq('seller_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch single service details with reviews
  static Future<Map<String, dynamic>> getServiceDetails(String serviceId) async {
    final data = await _client
        .from('services')
        .select('*, profiles!seller_id(id, name, profile_image_url)')
        .eq('id', serviceId)
        .single();
    return data;
  }

  /// Fetch reviews for a service
  static Future<List<Map<String, dynamic>>> getServiceReviews(String serviceId) async {
    final data = await _client
        .from('reviews')
        .select('*, profiles:reviewer_id(name, profile_image_url)')
        .eq('service_id', serviceId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Toggle service status (active/paused)
  static Future<void> toggleServiceStatus(String serviceId) async {
    final service = await _client
        .from('services')
        .select('status')
        .eq('id', serviceId)
        .single();

    final newStatus = service['status'] == 'active' ? 'paused' : 'active';
    await _client.from('services').update({'status': newStatus}).eq('id', serviceId);
  }

  /// Delete a service
  static Future<void> deleteService(String serviceId) async {
    await _client.from('services').delete().eq('id', serviceId);
  }

  /// Update service fields
  static Future<void> updateService(String serviceId, Map<String, dynamic> updates) async {
    await _client.from('services').update(updates).eq('id', serviceId);
  }

  /// Create a new service
  static Future<Map<String, dynamic>> createService({
    required String title,
    required String description,
    String? categoryId,
    String? subCategoryId,
    required String serviceType,
    required double price,
    required int deliveryTime,
    required int revisionCount,
    List<String> imageUrls = const [],
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final data = await _client.from('services').insert({
      'seller_id': user.id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'service_type': serviceType,
      'price': price,
      'delivery_time': deliveryTime,
      'revision_count': revisionCount,
      'images': imageUrls,
      'status': 'active',
    }).select().single();

    return data;
  }

  /// Upload service images to Supabase Storage
  static Future<List<String>> uploadServiceImages(List<File> imageFiles) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final List<String> urls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < imageFiles.length; i++) {
      final ext = imageFiles[i].path.split('.').last;
      final path = '${user.id}/${timestamp}_$i.$ext';

      await _client.storage.from('service-images').upload(
        path,
        imageFiles[i],
        fileOptions: const FileOptions(upsert: true),
      );

      final url = _client.storage.from('service-images').getPublicUrl(path);
      urls.add(url);
    }

    return urls;
  }

  /// Add service requirements
  static Future<void> addServiceRequirements(String serviceId, List<Map<String, dynamic>> requirements) async {
    if (requirements.isEmpty) return;

    final rows = requirements.map((r) => {
      'service_id': serviceId,
      'question': r['question'],
      'is_required': r['is_required'] ?? true,
    }).toList();

    await _client.from('service_requirements').insert(rows);
  }

  /// Fetch categories for dropdown
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await _client.from('categories').select('id, name').order('name');
    return List<Map<String, dynamic>>.from(data);
  }
}
