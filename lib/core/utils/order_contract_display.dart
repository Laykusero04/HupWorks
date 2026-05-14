import 'package:freelancer/core/utils/job_offer_delivery.dart';

/// Resolves title, description, and related copy for `orders` rows that may
/// come from either a marketplace `services` row or a job-offer contract
/// (`job_offers` + `job_posts`, with `service_id` null).
class OrderContractDisplay {
  OrderContractDisplay._();

  static Map<String, dynamic>? _asMap(Object? v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is List && v.isNotEmpty) return _asMap(v.first);
    return null;
  }

  static Map<String, dynamic>? jobOfferFromOrder(Map<String, dynamic>? order) =>
      _asMap(order?['job_offers']);

  static Map<String, dynamic>? jobPostFromOrder(Map<String, dynamic>? order) {
    final jo = jobOfferFromOrder(order);
    return _asMap(jo?['job_posts']);
  }

  /// Primary line for the contract (job post title or service title).
  static String title(Map<String, dynamic>? order, Map<String, dynamic>? service) {
    final jp = jobPostFromOrder(order);
    final jobTitle = (jp?['title'] as String?)?.trim();
    if (jobTitle != null && jobTitle.isNotEmpty) return jobTitle;
    final serviceTitle = (service?['title'] as String?)?.trim();
    if (serviceTitle != null && serviceTitle.isNotEmpty) return serviceTitle;
    return 'Contract';
  }

  /// Longer context: job description, seller cover letter, or service description.
  static String serviceInfo(Map<String, dynamic>? order, Map<String, dynamic>? service) {
    final jp = jobPostFromOrder(order);
    final postDesc = (jp?['description'] as String?)?.trim();
    if (postDesc != null && postDesc.isNotEmpty) return postDesc;
    final jo = jobOfferFromOrder(order);
    final letter = (jo?['cover_letter'] as String?)?.trim();
    if (letter != null && letter.isNotEmpty) return letter;
    return (service?['description'] as String?)?.trim() ?? '';
  }

  static String durationLabel(Map<String, dynamic>? order, Map<String, dynamic>? service) {
    final jo = jobOfferFromOrder(order);
    if (jo != null) {
      return JobOfferDelivery.formatLabel(jo['delivery_time'], jo['delivery_time_unit']);
    }
    final days = service?['delivery_time'];
    final d = days is int ? days : (days is num ? days.round() : int.tryParse('$days') ?? 0);
    if (d <= 0) return '—';
    return d == 1 ? '1 day' : '$d days';
  }

  static String revisionsLabel(Map<String, dynamic>? order, Map<String, dynamic>? service) {
    if (jobPostFromOrder(order) != null) return 'Per job agreement';
    final n = service?['revision_count'];
    final count = n is int ? n : (n is num ? n.round() : int.tryParse('$n') ?? 0);
    if (count == 0) return 'Unlimited Revisions';
    return count == 1 ? '1 Revision' : '$count Revisions';
  }
}
