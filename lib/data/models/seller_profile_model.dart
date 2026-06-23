import 'package:equatable/equatable.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';

class SellerProfile extends Equatable {
  final String id;
  final String userId;
  final List<SellerSkill> skills;
  final String? jobTitle;
  final List<String> languages;
  final String? languageLevel;
  final String? education;
  final String? experience;
  final String? about;
  final int impressionsCount;
  final int interactionsCount;
  final int reachCount;
  final DateTime createdAt;

  const SellerProfile({
    required this.id,
    required this.userId,
    this.skills = const [],
    this.jobTitle,
    this.languages = const [],
    this.languageLevel,
    this.education,
    this.experience,
    this.about,
    this.impressionsCount = 0,
    this.interactionsCount = 0,
    this.reachCount = 0,
    required this.createdAt,
  });

  static List<SellerSkill> _parseSkills(dynamic raw) {
    if (raw is! List) return const [];
    final result = <SellerSkill>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final skill = SellerSkill.fromJson(item);
        if (skill.name.isNotEmpty) result.add(skill);
      } else if (item is Map) {
        final skill = SellerSkill.fromJson(Map<String, dynamic>.from(item));
        if (skill.name.isNotEmpty) result.add(skill);
      } else if (item is String && item.trim().isNotEmpty) {
        result.add(SellerSkill(name: item.trim(), stars: 5));
      }
    }
    return result;
  }

  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      skills: _parseSkills(json['skills']),
      jobTitle: json['job_title'] as String?,
      languages: (json['languages'] as List?)?.cast<String>() ?? [],
      languageLevel: json['language_level'] as String?,
      education: json['education'] as String?,
      experience: json['experience'] as String?,
      about: json['about'] as String?,
      impressionsCount: (json['impressions_count'] as int?) ?? 0,
      interactionsCount: (json['interactions_count'] as int?) ?? 0,
      reachCount: (json['reach_count'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'skills': skills.map((s) => s.toJson()).toList(),
        'job_title': jobTitle,
        'languages': languages,
        'language_level': languageLevel,
        'education': education,
        'experience': experience,
        'about': about,
        'impressions_count': impressionsCount,
        'interactions_count': interactionsCount,
        'reach_count': reachCount,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        skills,
        jobTitle,
        languages,
        languageLevel,
        education,
        experience,
        about,
        impressionsCount,
        interactionsCount,
        reachCount,
        createdAt,
      ];
}
