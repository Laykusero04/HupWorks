import 'package:equatable/equatable.dart';

import '../../core/utils/job_offer_delivery.dart';
import '../../services/job_posts_service.dart';
import 'profile_model.dart';

class JobOffer extends Equatable {
  final String id;
  final String jobPostId;
  final String sellerId;
  final double price;
  final String priceBasis;
  final int? deliveryTime;
  final String? deliveryTimeUnit;
  final String? coverLetter;
  final String status;
  final DateTime createdAt;

  // Joined data
  final Profile? seller;

  const JobOffer({
    required this.id,
    required this.jobPostId,
    required this.sellerId,
    required this.price,
    this.priceBasis = JobPostsService.budgetBasisFixed,
    this.deliveryTime,
    this.deliveryTimeUnit,
    this.coverLetter,
    this.status = 'pending',
    required this.createdAt,
    this.seller,
  });

  factory JobOffer.fromJson(Map<String, dynamic> json) {
    final sellerData = json['profiles'] ?? json['seller'];

    return JobOffer(
      id: json['id'] as String,
      jobPostId: json['job_post_id'] as String,
      sellerId: json['seller_id'] as String,
      price: (json['price'] as num).toDouble(),
      priceBasis: JobPostsService.normalizeBudgetBasis(json['price_basis']),
      deliveryTime: json['delivery_time'] as int?,
      deliveryTimeUnit: json['delivery_time'] == null ? null : JobOfferDelivery.normalizeUnit(json['delivery_time_unit']),
      coverLetter: json['cover_letter'] as String?,
      status: (json['status'] as String?) ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      seller: sellerData is Map<String, dynamic> ? Profile.fromJson(sellerData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_post_id': jobPostId,
        'seller_id': sellerId,
        'price': price,
        'price_basis': priceBasis,
        'delivery_time': deliveryTime,
        'delivery_time_unit': deliveryTimeUnit,
        'cover_letter': coverLetter,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, jobPostId, sellerId, price, priceBasis, deliveryTime, deliveryTimeUnit, coverLetter, status, createdAt, seller];
}
