import 'dart:io';

import '../../core/errors/failures.dart';
import '../../services/client_home_service.dart';
import '../../services/recently_viewed_service.dart';
import '../../services/seller_service_management.dart';
import '../../services/service_details_service.dart';
import '../models/profile_model.dart';
import '../models/review_model.dart';
import '../models/service_model.dart';
import '../models/service_requirement_model.dart';

class ServiceRepository {
  // ── Client-facing ──

  Future<List<ServiceModel>> getPopularServices({int limit = 10}) async {
    try {
      final data = await ClientHomeService.getPopularServices(limit: limit);
      return data.map((m) => ServiceModel.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<Profile>> getTopSellers() async {
    try {
      final data = await ClientHomeService.getTopSellers();
      return data.map((m) => Profile.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<ServiceModel>> searchServices(String query) async {
    try {
      final data = await ClientHomeService.searchServices(query);
      return data.map((m) => ServiceModel.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<ServiceModel>> getRecentlyViewed({int limit = 10}) async {
    try {
      final data = await RecentlyViewedService.getRecentlyViewedServices(limit: limit);
      return data.map((m) => ServiceModel.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> addRecentlyViewed(String serviceId) async {
    await RecentlyViewedService.addServiceId(serviceId);
  }

  // ── Service details ──

  Future<ServiceModel> getServiceDetails(String serviceId) async {
    try {
      final data = await ServiceDetailsService.getServiceDetails(serviceId);
      return ServiceModel.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<Review>> getServiceReviews(String serviceId) async {
    try {
      final data = await ServiceDetailsService.getServiceReviews(serviceId);
      return data.map((m) => Review.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<ServiceRequirement>> getServiceRequirements(String serviceId) async {
    try {
      final data = await ServiceDetailsService.getServiceRequirements(serviceId);
      return data.map((m) => ServiceRequirement.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<bool> isFavourited(String serviceId) async {
    try {
      return await ServiceDetailsService.isFavourited(serviceId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<bool> toggleFavourite(String serviceId) async {
    try {
      return await ServiceDetailsService.toggleFavourite(serviceId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Seller service management ──

  Future<List<ServiceModel>> getMyServices() async {
    try {
      final data = await SellerServiceManagement.getMyServices();
      return data.map((m) => ServiceModel.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> toggleServiceStatus(String serviceId) async {
    try {
      await SellerServiceManagement.toggleServiceStatus(serviceId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await SellerServiceManagement.deleteService(serviceId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> updates) async {
    try {
      await SellerServiceManagement.updateService(serviceId, updates);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<ServiceModel> createService({
    required String title,
    required String description,
    String? categoryId,
    String? subCategoryId,
    required String serviceType,
    required double price,
    required int deliveryTime,
    required int revisionCount,
    List<String> imageUrls = const [],
  }) async {
    try {
      final data = await SellerServiceManagement.createService(
        title: title,
        description: description,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        serviceType: serviceType,
        price: price,
        deliveryTime: deliveryTime,
        revisionCount: revisionCount,
        imageUrls: imageUrls,
      );
      return ServiceModel.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<String>> uploadServiceImages(List<File> imageFiles) async {
    try {
      return await SellerServiceManagement.uploadServiceImages(imageFiles);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> addServiceRequirements(String serviceId, List<Map<String, dynamic>> requirements) async {
    try {
      await SellerServiceManagement.addServiceRequirements(serviceId, requirements);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
