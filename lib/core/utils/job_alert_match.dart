import 'dart:math' as math;

/// Client-side mirror of [job_post_matches_alert_rule] (Postgres) for previews.
abstract final class JobAlertMatch {
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double deg) => deg * math.pi / 180;

  static bool jobMatchesRule({
    required String? title,
    required String? description,
    required String? categoryName,
    required String? categoryId,
    required String? jobType,
    required String? locationType,
    required double? jobLat,
    required double? jobLng,
    required double? sellerLat,
    required double? sellerLng,
    required List<String> categoryIds,
    required List<String> skillNames,
    required String? ruleJobType,
    required double? maxDistanceKm,
    required bool includeRemote,
  }) {
    if (categoryIds.isNotEmpty) {
      if (categoryId == null || !categoryIds.contains(categoryId)) {
        return false;
      }
    }

    if (skillNames.isNotEmpty) {
      final titleL = (title ?? '').toLowerCase();
      final descL = (description ?? '').toLowerCase();
      final catL = (categoryName ?? '').toLowerCase();
      var matched = false;
      for (final raw in skillNames) {
        final skill = raw.trim().toLowerCase();
        if (skill.isEmpty) continue;
        if (titleL.contains(skill) || descL.contains(skill) || catL.contains(skill)) {
          matched = true;
          break;
        }
      }
      if (!matched) return false;
    }

    if (ruleJobType != null && ruleJobType.isNotEmpty && ruleJobType != jobType) {
      return false;
    }

    if ((locationType ?? '') == 'Remote') {
      return includeRemote;
    }

    if (maxDistanceKm == null) return true;

    if (sellerLat == null ||
        sellerLng == null ||
        jobLat == null ||
        jobLng == null) {
      return false;
    }

    return haversineKm(sellerLat, sellerLng, jobLat, jobLng) <= maxDistanceKm;
  }
}
