import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerHomeService {
  static final _client = Supabase.instance.client;

  /// Fetch seller profile + seller_profiles data
  static Future<Map<String, dynamic>?> getSellerProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select('*, seller_profiles(*)')
        .eq('id', user.id)
        .single();
    return data;
  }

  /// Job-focused dashboard metrics for the freelancer home screen.
  static Future<Map<String, dynamic>> getWorkOverview() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final orders = await _client
        .from('orders')
        .select('id, status, price, created_at')
        .eq('seller_id', user.id);

    final orderList = List<Map<String, dynamic>>.from(orders);
    int activeContracts = 0;
    int deliveredAwaiting = 0;
    int completedThisMonth = 0;

    for (final o in orderList) {
      final st = (o['status'] as String?)?.toLowerCase() ?? '';
      if (st == 'pending' || st == 'active') activeContracts++;
      if (st == 'delivered') {
        activeContracts++;
        deliveredAwaiting++;
      }
      if (st == 'completed') {
        final created = DateTime.tryParse(o['created_at'] as String? ?? '');
        if (created != null && !created.isBefore(monthStart)) {
          completedThisMonth++;
        }
      }
    }

    final offers = await _client
        .from('job_offers')
        .select('id, status')
        .eq('seller_id', user.id);

    final offerList = List<Map<String, dynamic>>.from(offers);
    var pendingApplications = 0;
    var acceptedApplications = 0;
    for (final o in offerList) {
      final st = (o['status'] as String?)?.toLowerCase() ?? '';
      if (st == 'pending') pendingApplications++;
      if (st == 'accepted') acceptedApplications++;
    }

    final openJobs = await _client
        .from('job_posts')
        .select('id')
        .eq('status', 'open');
    final openJobsCount = (openJobs as List).length;

    final reviews = await _client
        .from('reviews')
        .select('rating')
        .eq('reviewed_id', user.id);
    final reviewList = List<Map<String, dynamic>>.from(reviews);
    double avgRating = 0;
    if (reviewList.isNotEmpty) {
      avgRating = reviewList.fold<double>(
            0,
            (sum, r) => sum + (r['rating'] as num).toDouble(),
          ) /
          reviewList.length;
    }

    var onsiteAttendanceCount = 0;
    try {
      final attJobs = await AttendanceService.getMyOnsiteAttendanceJobs();
      onsiteAttendanceCount = attJobs.length;
    } catch (e, st) {
      AppLogger.error('SellerHomeService.onsiteAttendanceCount', e, st);
    }

    return {
      'active_contracts': activeContracts,
      'delivered_awaiting_approval': deliveredAwaiting,
      'completed_this_month': completedThisMonth,
      'pending_applications': pendingApplications,
      'accepted_applications': acceptedApplications,
      'total_applications': offerList.length,
      'open_jobs_count': openJobsCount,
      'avg_rating': avgRating,
      'review_count': reviewList.length,
      'onsite_attendance_jobs': onsiteAttendanceCount,
    };
  }

  /// Fetch performance metrics for a given period
  static Future<Map<String, dynamic>> getPerformance({required bool isLastMonth}) async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final now = DateTime.now();
    final DateTime startDate;
    final DateTime endDate;

    if (isLastMonth) {
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, now.month, 1);
      endDate = now;
    }

    // Fetch orders in the period
    final orders = await _client
        .from('orders')
        .select('id, status')
        .eq('seller_id', user.id)
        .gte('created_at', startDate.toIso8601String())
        .lt('created_at', endDate.toIso8601String());

    final orderList = List<Map<String, dynamic>>.from(orders);
    final totalOrders = orderList.length;
    final completedOrders = orderList.where((o) => o['status'] == 'completed').length;

    // Fetch services count
    final services = await _client
        .from('services')
        .select('id')
        .eq('seller_id', user.id);

    final activeServices = List.from(services).length;

    // Fetch average rating
    final reviews = await _client
        .from('reviews')
        .select('rating')
        .eq('reviewed_id', user.id);

    final reviewList = List<Map<String, dynamic>>.from(reviews);
    double avgRating = 0;
    if (reviewList.isNotEmpty) {
      avgRating = reviewList.fold<double>(0, (sum, r) => sum + (r['rating'] as num).toDouble()) / reviewList.length;
    }

    return {
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'avg_rating': avgRating,
      'total_services': activeServices,
    };
  }

  /// Fetch statistics (impressions, interactions, reach) from seller_profiles
  static Future<Map<String, double>> getStatistics() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final data = await _client
        .from('seller_profiles')
        .select('impressions_count, interactions_count, reach_count')
        .eq('user_id', user.id)
        .single();

    return {
      'Impressions': (data['impressions_count'] as num?)?.toDouble() ?? 0,
      'Interaction': (data['interactions_count'] as num?)?.toDouble() ?? 0,
      'Reached-Out': (data['reach_count'] as num?)?.toDouble() ?? 0,
    };
  }

  /// Fetch seller's services
  static Future<List<Map<String, dynamic>>> getMyServices({int limit = 10}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('services')
        .select()
        .eq('seller_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }
}
