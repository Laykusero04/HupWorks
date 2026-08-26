import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceDetailsService {
  static final _client = Supabase.instance.client;

  /// Fetch full service data + seller info
  static Future<Map<String, dynamic>> getServiceDetails(String serviceId) async {
    final data = await _client
        .from('services')
        .select('*, profiles!seller_id(id, name, email, profile_image_url, rating)')
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

  /// Fetch service requirements
  static Future<List<Map<String, dynamic>>> getServiceRequirements(String serviceId) async {
    final data = await _client
        .from('service_requirements')
        .select()
        .eq('service_id', serviceId);
    return List<Map<String, dynamic>>.from(data);
  }
}
