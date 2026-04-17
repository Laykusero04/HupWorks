import '../../core/errors/failures.dart';
import '../../services/client_home_service.dart';
import '../models/category_model.dart';

class CategoryRepository {
  Future<List<Category>> getCategories() async {
    try {
      final data = await ClientHomeService.getCategories();
      return data.map((m) => Category.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
