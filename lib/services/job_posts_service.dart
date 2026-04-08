import 'package:supabase_flutter/supabase_flutter.dart';

class JobPostsService {
  static final _client = Supabase.instance.client;

  /// Fetch client's job posts
  static Future<List<Map<String, dynamic>>> getClientJobPosts() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('job_posts')
        .select('*, categories(name)')
        .eq('client_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Create a new job post
  static Future<Map<String, dynamic>> createJobPost({
    required String title,
    required String description,
    String? categoryId,
    double? budgetMin,
    double? budgetMax,
    DateTime? deadline,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final data = await _client.from('job_posts').insert({
      'client_id': user.id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'deadline': deadline?.toIso8601String(),
      'status': 'open',
    }).select().single();

    return data;
  }

  /// Fetch single job post details
  static Future<Map<String, dynamic>> getJobPostDetails(String jobPostId) async {
    final data = await _client
        .from('job_posts')
        .select('*, categories(name)')
        .eq('id', jobPostId)
        .single();
    return data;
  }

  /// Fetch seller offers on a job post
  static Future<List<Map<String, dynamic>>> getJobOffers(String jobPostId) async {
    final data = await _client
        .from('job_offers')
        .select('*, profiles:seller_id(name, profile_image_url, rating)')
        .eq('job_post_id', jobPostId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Accept or reject an offer
  static Future<void> updateOfferStatus(String offerId, String status) async {
    await _client.from('job_offers').update({'status': status}).eq('id', offerId);
  }

  /// Close a job post
  static Future<void> closeJobPost(String jobPostId) async {
    await _client.from('job_posts').update({'status': 'closed'}).eq('id', jobPostId);
  }

  /// Fetch categories for dropdown
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await _client.from('categories').select('id, name').order('name');
    return List<Map<String, dynamic>>.from(data);
  }
}
