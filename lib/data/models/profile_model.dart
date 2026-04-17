import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String role;
  final String name;
  final String email;
  final String? phone;
  final String? country;
  final String? city;
  final String? gender;
  final String? profileImageUrl;
  final String? bio;
  final double rating;
  final double balance;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.country,
    this.city,
    this.gender,
    this.profileImageUrl,
    this.bio,
    this.rating = 0,
    this.balance = 0,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      gender: json['gender'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      bio: json['bio'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'name': name,
        'email': email,
        'phone': phone,
        'country': country,
        'city': city,
        'gender': gender,
        'profile_image_url': profileImageUrl,
        'bio': bio,
        'rating': rating,
        'balance': balance,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, role, name, email, phone, country, city, gender, profileImageUrl, bio, rating, balance, createdAt];
}
