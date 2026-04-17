import '../../core/errors/failures.dart';
import '../../services/dashboard_service.dart';
import '../../services/seller_home_service.dart';
import '../models/favourite_model.dart';
import '../models/profile_model.dart';
import '../models/service_model.dart';

class DashboardRepository {
  // ── Client dashboard ──

  Future<Map<String, dynamic>> getClientDashboard() async {
    try {
      return await DashboardService.getClientDashboard();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<Favourite>> getFavourites() async {
    try {
      final data = await DashboardService.getFavourites();
      return data.map((m) => Favourite.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> removeFavourite(String favouriteId) async {
    try {
      await DashboardService.removeFavourite(favouriteId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Seller dashboard ──

  Future<Profile?> getSellerProfile() async {
    try {
      final data = await SellerHomeService.getSellerProfile();
      if (data == null) return null;
      return Profile.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Map<String, dynamic>> getPerformance({required bool isLastMonth}) async {
    try {
      return await SellerHomeService.getPerformance(isLastMonth: isLastMonth);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Map<String, double>> getStatistics() async {
    try {
      return await SellerHomeService.getStatistics();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Map<String, dynamic>> getEarnings({required bool isLastMonth}) async {
    try {
      return await SellerHomeService.getEarnings(isLastMonth: isLastMonth);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<ServiceModel>> getSellerMyServices({int limit = 10}) async {
    try {
      final data = await SellerHomeService.getMyServices(limit: limit);
      return data.map((m) => ServiceModel.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
