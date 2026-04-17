import 'package:equatable/equatable.dart';

class SubCategory extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final DateTime? createdAt;

  const SubCategory({
    required this.id,
    required this.categoryId,
    required this.name,
    this.createdAt,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, categoryId, name, createdAt];
}
