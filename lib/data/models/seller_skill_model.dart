import 'package:equatable/equatable.dart';

class SellerSkill extends Equatable {
  final String name;
  final int stars;

  const SellerSkill({
    required this.name,
    required this.stars,
  });

  factory SellerSkill.fromJson(Map<String, dynamic> json) {
    return SellerSkill(
      name: (json['name'] as String? ?? '').trim(),
      stars: (json['stars'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'stars': stars,
      };

  SellerSkill copyWith({String? name, int? stars}) {
    return SellerSkill(
      name: name ?? this.name,
      stars: stars ?? this.stars,
    );
  }

  @override
  List<Object?> get props => [name, stars];
}
