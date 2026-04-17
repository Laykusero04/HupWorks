import 'package:equatable/equatable.dart';

import 'profile_model.dart';

class Review extends Equatable {
  final String id;
  final String orderId;
  final String reviewerId;
  final String reviewedId;
  final String serviceId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  // Joined data
  final Profile? reviewer;

  const Review({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.reviewedId,
    required this.serviceId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewer,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final reviewerData = json['profiles'] ?? json['reviewer'];

    return Review(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      reviewedId: json['reviewed_id'] as String,
      serviceId: json['service_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewer: reviewerData is Map<String, dynamic> ? Profile.fromJson(reviewerData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'reviewer_id': reviewerId,
        'reviewed_id': reviewedId,
        'service_id': serviceId,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, orderId, reviewerId, reviewedId, serviceId, rating, comment, createdAt, reviewer];
}
