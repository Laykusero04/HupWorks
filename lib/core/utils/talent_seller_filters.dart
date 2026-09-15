import 'package:freelancer/core/utils/seller_standing.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/verification_service.dart';

/// Employer pin used for nearby talent search (saved on [profiles]).
class TalentFilterOrigin {
  const TalentFilterOrigin({
    this.latitude,
    this.longitude,
    this.city,
    this.country,
  });

  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;

  static const empty = TalentFilterOrigin();

  bool get hasCoordinates => latitude != null && longitude != null;

  String get locationLabel {
    final parts = [
      city?.trim(),
      country?.trim(),
    ].whereType<String>().where((s) => s.isNotEmpty);
    return parts.join(', ');
  }

  TalentFilterOrigin copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
  }) {
    return TalentFilterOrigin(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }

  static TalentFilterOrigin fromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return empty;
    return TalentFilterOrigin(
      latitude: ProfileService.latitudeFromProfile(profile),
      longitude: ProfileService.longitudeFromProfile(profile),
      city: profile['city'] as String?,
      country: profile['country'] as String?,
    );
  }
}

/// Client-side filters for freelancer / talent lists.
class TalentSellerFilters {
  const TalentSellerFilters({
    this.verifiedOnly,
    this.standing,
    this.minRating,
    this.maxDistanceKm,
  });

  /// `true` = verified only; `null` = any.
  final bool? verifiedOnly;
  final SellerStanding? standing;
  final double? minRating;

  /// When set, seller fetch must use nearby RPC (not client-side haversine).
  final double? maxDistanceKm;

  static const minRatingOptions = <double>[3.5, 4.0, 4.5];
  static const distanceMinKm = 5.0;
  static const distanceMaxKm = 100.0;
  static const distanceDefaultKm = 25.0;

  static const empty = TalentSellerFilters();

  bool get hasActive =>
      verifiedOnly == true ||
      standing != null ||
      minRating != null ||
      maxDistanceKm != null;

  bool get usesNearbySearch => maxDistanceKm != null;

  int get activeCount {
    var n = 0;
    if (verifiedOnly == true) n++;
    if (standing != null) n++;
    if (minRating != null) n++;
    if (maxDistanceKm != null) n++;
    return n;
  }

  TalentSellerFilters copyWith({
    bool? verifiedOnly,
    SellerStanding? standing,
    double? minRating,
    double? maxDistanceKm,
    bool clearVerified = false,
    bool clearStanding = false,
    bool clearMinRating = false,
    bool clearMaxDistance = false,
  }) {
    return TalentSellerFilters(
      verifiedOnly: clearVerified ? null : (verifiedOnly ?? this.verifiedOnly),
      standing: clearStanding ? null : (standing ?? this.standing),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      maxDistanceKm:
          clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
    );
  }

  /// Optional [query] also matches name / job title / about / skills (local).
  /// Distance is applied server-side — not here.
  static List<Map<String, dynamic>> apply(
    List<Map<String, dynamic>> sellers, {
    TalentSellerFilters filters = empty,
    String query = '',
  }) {
    final q = query.trim().toLowerCase();

    return sellers.where((seller) {
      if (q.isNotEmpty) {
        final name = (seller['name'] as String? ?? '').toLowerCase();
        final sp = sellerProfileRow(seller);
        final jobTitle = (sp?['job_title'] as String? ?? '').toLowerCase();
        final about = (sp?['about'] as String? ?? '').toLowerCase();
        final skillNames = ProfileService.sellerSkillsFromProfile(seller)
            .map((s) => s.name.toLowerCase())
            .join(' ');
        final matchesSearch = name.contains(q) ||
            jobTitle.contains(q) ||
            about.contains(q) ||
            skillNames.contains(q);
        if (!matchesSearch) return false;
      }

      if (filters.verifiedOnly == true) {
        if (VerificationService.statusFromProfile(seller) != 'verified') {
          return false;
        }
      }

      final rating = double.tryParse('${seller['rating'] ?? 0}') ?? 0;
      final reviewCount = (seller['review_count'] as num?)?.toInt() ?? 0;

      if (filters.minRating != null && rating < filters.minRating!) {
        return false;
      }

      if (filters.standing != null) {
        final standing = SellerStandingResolver.resolve(
          rating: rating,
          reviewCount: reviewCount,
        );
        if (standing != filters.standing) return false;
      }

      return true;
    }).toList();
  }

  static Map<String, dynamic>? sellerProfileRow(Map<String, dynamic> seller) {
    final sp = seller['seller_profiles'];
    if (sp is Map<String, dynamic>) return sp;
    if (sp is List && sp.isNotEmpty && sp.first is Map<String, dynamic>) {
      return sp.first as Map<String, dynamic>;
    }
    return null;
  }
}
