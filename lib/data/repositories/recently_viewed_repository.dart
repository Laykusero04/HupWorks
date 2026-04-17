import '../../core/errors/failures.dart';
import '../../services/recently_viewed_service.dart';
import '../models/service_model.dart';

class RecentlyViewedRepository {
  Future<List<ServiceModel>> getRecentlyViewedServices({int limit = 10}) async {
    try {
      final data = await RecentlyViewedService.getRecentlyViewedServices(limit: limit);
      return data.map((m) => ServiceModel.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> addServiceId(String serviceId) async {
    await RecentlyViewedService.addServiceId(serviceId);
  }

  Future<void> clear() async {
    await RecentlyViewedService.clear();
  }
}
