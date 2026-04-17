import 'package:equatable/equatable.dart';

class SellerProfile extends Equatable {
  final String id;
  final String userId;
  final List<String> skills;
  final String? skillLevel;
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
    this.skillLevel,
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

  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      skills: (json['skills'] as List?)?.cast<String>() ?? [],
      skillLevel: json['skill_level'] as String?,
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
        'skills': skills,
        'skill_level': skillLevel,
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
  List<Object?> get props => [id, userId, skills, skillLevel, languages, languageLevel, education, experience, about, impressionsCount, interactionsCount, reachCount, createdAt];
}
