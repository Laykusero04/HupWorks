import '../../core/errors/failures.dart';
import '../../services/job_posts_service.dart';
import '../../services/seller_orders_service.dart';
import '../models/job_offer_model.dart';
import '../models/job_post_model.dart';

class JobPostRepository {
  // ── Client job posts ──

  Future<List<JobPost>> getClientJobPosts() async {
    try {
      final data = await JobPostsService.getClientJobPosts();
      return data.map((m) => JobPost.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<JobPost> createJobPost({
    required String title,
    required String description,
    String? categoryId,
    double? budgetMin,
    double? budgetMax,
    DateTime? deadline,
  }) async {
    try {
      final data = await JobPostsService.createJobPost(
        title: title,
        description: description,
        categoryId: categoryId,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        deadline: deadline,
      );
      return JobPost.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<JobPost> getJobPostDetails(String jobPostId) async {
    try {
      final data = await JobPostsService.getJobPostDetails(jobPostId);
      return JobPost.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<JobOffer>> getJobOffers(String jobPostId) async {
    try {
      final data = await JobPostsService.getJobOffers(jobPostId);
      return data.map((m) => JobOffer.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> updateOfferStatus(String offerId, String status) async {
    try {
      await JobPostsService.updateOfferStatus(offerId, status);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> closeJobPost(String jobPostId) async {
    try {
      await JobPostsService.closeJobPost(jobPostId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Seller buyer requests ──

  Future<List<JobPost>> getBuyerRequests() async {
    try {
      final data = await SellerOrdersService.getBuyerRequests();
      return data.map((m) => JobPost.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<JobPost> getBuyerRequestDetails(String jobPostId) async {
    try {
      final data = await SellerOrdersService.getBuyerRequestDetails(jobPostId);
      return JobPost.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> createOffer({
    required String jobPostId,
    required double price,
    required int deliveryTime,
    String? coverLetter,
  }) async {
    try {
      await SellerOrdersService.createOffer(
        jobPostId: jobPostId,
        price: price,
        deliveryTime: deliveryTime,
        coverLetter: coverLetter,
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
