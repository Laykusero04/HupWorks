import 'package:equatable/equatable.dart';

import 'category_model.dart';
import 'profile_model.dart';

class JobPost extends Equatable {
  final String id;
  final String clientId;
  final String title;
  final String? description;
  final String? categoryId;
  final double? budgetMin;
  final double? budgetMax;
  final DateTime? deadline;
  final String status;
  final DateTime createdAt;

  // Joined data
  final Category? category;
  final Profile? client;

  const JobPost({
    required this.id,
    required this.clientId,
    required this.title,
    this.description,
    this.categoryId,
    this.budgetMin,
    this.budgetMax,
    this.deadline,
    this.status = 'open',
    required this.createdAt,
    this.category,
    this.client,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    final categoryData = json['categories'] ?? json['category'];
    final clientData = json['profiles'] ?? json['client'];

    return JobPost(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      budgetMin: (json['budget_min'] as num?)?.toDouble(),
      budgetMax: (json['budget_max'] as num?)?.toDouble(),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      status: (json['status'] as String?) ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
      category: categoryData is Map<String, dynamic> ? Category.fromJson(categoryData) : null,
      client: clientData is Map<String, dynamic> ? Profile.fromJson(clientData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        if (deadline != null) 'deadline': deadline!.toIso8601String(),
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, clientId, title, description, categoryId, budgetMin, budgetMax, deadline, status, createdAt, category, client];
}
