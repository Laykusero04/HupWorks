import 'package:equatable/equatable.dart';

import 'job_post_model.dart';

class Favourite extends Equatable {
  final String id;
  final String userId;
  final String jobPostId;
  final DateTime createdAt;

  /// Joined job post when selected with `job_posts(...)`.
  final JobPost? jobPost;

  const Favourite({
    required this.id,
    required this.userId,
    required this.jobPostId,
    required this.createdAt,
    this.jobPost,
  });

  factory Favourite.fromJson(Map<String, dynamic> json) {
    final jobData = json['job_posts'] ?? json['job_post'];

    return Favourite(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      jobPostId: json['job_post_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      jobPost: jobData is Map<String, dynamic> ? JobPost.fromJson(jobData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'job_post_id': jobPostId,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, userId, jobPostId, createdAt, jobPost];
}
