import '../repositories/menu_repository.dart';
import '../../models/dish.dart';
import 'fixture_data.dart';

class FixtureMenuRepository implements MenuRepository {
  final List<Dish> _dishes = List.from(FixtureData.sampleDishes);

  @override
  Future<List<Dish>> getDishes() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_dishes);
  }

  @override
  Future<Dish?> getDishById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _dishes.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> getCategories() async {
    final categories = _dishes.map((d) => d.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  @override
  Future<List<Dish>> searchDishes(String query, {String? category}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _dishes.where((dish) {
      final matchesQuery = query.isEmpty ||
          dish.name.toLowerCase().contains(query.toLowerCase()) ||
          dish.description.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = category == null || category == 'All' || dish.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
  }
}
