import '../../core/networking/api_client.dart';
import '../../models/dish.dart';
import '../repositories/menu_repository.dart';

class RemoteMenuRepository implements MenuRepository {
  final ApiClient apiClient;

  RemoteMenuRepository({required this.apiClient});

  @override
  Future<List<Dish>> getDishes() async {
    final response = await apiClient.get('/menu/dishes');
    final list = response as List<dynamic>;
    return list.map((e) => Dish.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Dish?> getDishById(String id) async {
    final response = await apiClient.get('/menu/dishes/$id');
    return Dish.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<String>> getCategories() async {
    final response = await apiClient.get('/menu/categories');
    return List<String>.from(response as List);
  }

  @override
  Future<List<Dish>> searchDishes(String query, {String? category}) async {
    final response = await apiClient.get('/menu/search', queryParameters: {
      'q': query,
      if (category != null && category != 'All') 'category': category,
    });
    final list = response as List<dynamic>;
    return list.map((e) => Dish.fromJson(e as Map<String, dynamic>)).toList();
  }
}
