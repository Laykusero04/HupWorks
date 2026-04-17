import 'package:equatable/equatable.dart';

import 'profile_model.dart';

class ServiceModel extends Equatable {
  final String id;
  final String sellerId;
  final String title;
  final String? description;
  final String? categoryId;
  final String? subCategoryId;
  final String? serviceType;
  final double price;
  final int deliveryTime;
  final int revisionCount;
  final List<String> images;
  final String status;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;

  // Joined data
  final Profile? seller;

  const ServiceModel({
    required this.id,
    required this.sellerId,
    required this.title,
    this.description,
    this.categoryId,
    this.subCategoryId,
    this.serviceType,
    required this.price,
    required this.deliveryTime,
    this.revisionCount = 0,
    this.images = const [],
    this.status = 'active',
    this.rating = 0,
    this.reviewCount = 0,
    required this.createdAt,
    this.seller,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // Handle joined profiles data (can come as 'profiles' or 'seller')
    final sellerData = json['profiles'] ?? json['seller'];

    return ServiceModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      subCategoryId: json['sub_category_id'] as String?,
      serviceType: json['service_type'] as String?,
      price: (json['price'] as num).toDouble(),
      deliveryTime: json['delivery_time'] as int,
      revisionCount: (json['revision_count'] as int?) ?? 0,
      images: (json['images'] as List?)?.cast<String>() ?? [],
      status: (json['status'] as String?) ?? 'active',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      seller: sellerData is Map<String, dynamic> ? Profile.fromJson(sellerData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'sub_category_id': subCategoryId,
        'service_type': serviceType,
        'price': price,
        'delivery_time': deliveryTime,
        'revision_count': revisionCount,
        'images': images,
        'status': status,
        'rating': rating,
        'review_count': reviewCount,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, sellerId, title, description, categoryId, subCategoryId, serviceType, price, deliveryTime, revisionCount, images, status, rating, reviewCount, createdAt, seller];
}
