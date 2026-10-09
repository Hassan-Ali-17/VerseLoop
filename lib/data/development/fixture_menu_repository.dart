import '../repositories/menu_repository.dart';
import '../../models/dish.dart';
import 'fixture_data.dart';
import 'fixture_inventory_repository.dart';

class FixtureMenuRepository implements MenuRepository {
  final FixtureInventoryRepository? inventoryRepo;

  FixtureMenuRepository({this.inventoryRepo});

  List<Dish> get _allDishes => FixtureData.sampleDishes;

  Dish _syncWithInventory(Dish dish) {
    if (inventoryRepo != null) {
      final inv = inventoryRepo!.getInventoryItem(dish.id);
      if (inv != null) {
        return dish.copyWith(
          stockCount: inv.availablePortions,
          isAvailable: inv.isAvailable && inv.availablePortions > 0,
        );
      }
    }
    return dish;
  }

  @override
  Future<List<Dish>> getDishes() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _allDishes.map(_syncWithInventory).toList();
  }

  @override
  Future<Dish?> getDishById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final found = _allDishes.firstWhere((d) => d.id == id);
      return _syncWithInventory(found);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> getCategories() async {
    final categories = _allDishes.map((d) => d.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  @override
  Future<List<Dish>> searchDishes(String query, {String? category}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _allDishes.map(_syncWithInventory).where((dish) {
      final matchesQuery = query.isEmpty ||
          dish.name.toLowerCase().contains(query.toLowerCase()) ||
          dish.description.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = category == null || category == 'All' || dish.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
  }
}

