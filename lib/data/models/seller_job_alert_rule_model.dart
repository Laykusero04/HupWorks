import 'package:equatable/equatable.dart';

class SellerJobAlertRule extends Equatable {
  const SellerJobAlertRule({
    required this.id,
    required this.sellerId,
    this.name,
    this.enabled = true,
    this.categoryIds = const [],
    this.skillNames = const [],
    this.jobType,
    this.maxDistanceKm,
    this.includeRemote = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sellerId;
  final String? name;
  final bool enabled;
  final List<String> categoryIds;
  final List<String> skillNames;
  final String? jobType;
  final double? maxDistanceKm;
  final bool includeRemote;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SellerJobAlertRule.fromJson(Map<String, dynamic> json) {
    List<String> uuidList(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }

    List<String> textList(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }

    return SellerJobAlertRule(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      name: json['name'] as String?,
      enabled: (json['enabled'] as bool?) ?? true,
      categoryIds: uuidList(json['category_ids']),
      skillNames: textList(json['skill_names']),
      jobType: json['job_type'] as String?,
      maxDistanceKm: (json['max_distance_km'] as num?)?.toDouble(),
      includeRemote: (json['include_remote'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson({required String sellerId}) {
    return {
      'seller_id': sellerId,
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      'enabled': enabled,
      'category_ids': categoryIds,
      'skill_names': skillNames,
      if (jobType != null && jobType!.isNotEmpty) 'job_type': jobType,
      'max_distance_km': maxDistanceKm,
      'include_remote': includeRemote,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': (name == null || name!.trim().isEmpty) ? null : name!.trim(),
      'enabled': enabled,
      'category_ids': categoryIds,
      'skill_names': skillNames,
      'job_type': jobType,
      'max_distance_km': maxDistanceKm,
      'include_remote': includeRemote,
    };
  }

  SellerJobAlertRule copyWith({
    String? id,
    String? sellerId,
    String? name,
    bool? enabled,
    List<String>? categoryIds,
    List<String>? skillNames,
    String? jobType,
    double? maxDistanceKm,
    bool? includeRemote,
    bool clearMaxDistance = false,
    bool clearJobType = false,
    bool clearName = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerJobAlertRule(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: clearName ? null : (name ?? this.name),
      enabled: enabled ?? this.enabled,
      categoryIds: categoryIds ?? this.categoryIds,
      skillNames: skillNames ?? this.skillNames,
      jobType: clearJobType ? null : (jobType ?? this.jobType),
      maxDistanceKm: clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      includeRemote: includeRemote ?? this.includeRemote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sellerId,
        name,
        enabled,
        categoryIds,
        skillNames,
        jobType,
        maxDistanceKm,
        includeRemote,
        createdAt,
        updatedAt,
      ];
}
