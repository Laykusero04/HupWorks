import 'package:equatable/equatable.dart';

import '../../core/utils/localized_category.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final String? description;
  final Map<String, String> nameI18n;
  final Map<String, String> descriptionI18n;
  final DateTime? createdAt;

  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    this.nameI18n = const {},
    this.descriptionI18n = const {},
    this.createdAt,
  });

  String localizedName(String languageCode, {String fallback = ''}) {
    return LocalizedCategory.name(
      {
        'name': name,
        'name_i18n': nameI18n,
      },
      languageCode,
      fallback: fallback,
    );
  }

  String localizedDescription(String languageCode, {String fallback = ''}) {
    return LocalizedCategory.description(
      {
        'description': description,
        'description_i18n': descriptionI18n,
      },
      languageCode,
      fallback: fallback,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      nameI18n: _stringMap(json['name_i18n']),
      descriptionI18n: _stringMap(json['description_i18n']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'icon': icon,
        'description': description,
        'name_i18n': nameI18n,
        'description_i18n': descriptionI18n,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, String>{};
    for (final entry in raw.entries) {
      final value = entry.value?.toString().trim();
      if (value == null || value.isEmpty) continue;
      out[entry.key.toString()] = value;
    }
    return out;
  }

  @override
  List<Object?> get props =>
      [id, name, icon, description, nameI18n, descriptionI18n, createdAt];
}
