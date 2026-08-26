import 'package:supabase_flutter/supabase_flutter.dart';

/// Seller/freelancer saved jobs (`favourites.job_post_id`).
class FavouriteService {
  static final _client = Supabase.instance.client;

  static Future<bool> isFavourited(String jobPostId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final data = await _client
        .from('favourites')
        .select('id')
        .eq('user_id', user.id)
        .eq('job_post_id', jobPostId)
        .maybeSingle();

    return data != null;
  }

  /// Returns `true` if the job is favourited after the toggle.
  static Future<bool> toggleFavourite(String jobPostId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final existing = await _client
        .from('favourites')
        .select('id')
        .eq('user_id', user.id)
        .eq('job_post_id', jobPostId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('favourites')
          .delete()
          .eq('user_id', user.id)
          .eq('job_post_id', jobPostId);
      return false;
    }

    await _client.from('favourites').insert({
      'user_id': user.id,
      'job_post_id': jobPostId,
    });
    return true;
  }

  static Future<List<Map<String, dynamic>>> getFavourites() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('favourites')
        .select(
          'id, user_id, job_post_id, created_at, '
          'job_posts!job_post_id('
          'id, title, description, status, job_type, budget_min, budget_max, '
          'budget_basis, location, location_type, created_at, '
          'categories(name), '
          'client:profiles!client_id(id, name, profile_image_url)'
          ')',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> removeFavourite(String favouriteId) async {
    await _client.from('favourites').delete().eq('id', favouriteId);
  }

  /// Job post IDs the current user has saved (for list/card badges).
  static Future<Set<String>> getFavouritedJobPostIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final data = await _client
        .from('favourites')
        .select('job_post_id')
        .eq('user_id', user.id);

    return {
      for (final row in List<Map<String, dynamic>>.from(data))
        if (row['job_post_id'] is String) row['job_post_id'] as String,
    };
  }
}
