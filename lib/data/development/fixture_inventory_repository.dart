import '../repositories/inventory_repository.dart';
import '../../models/inventory_item.dart';
import 'fixture_data.dart';

class FixtureInventoryRepository implements InventoryRepository {
  static final Map<String, InventoryItem> _sharedInventoryMap = {
    for (var item in FixtureData.initialInventory) item.dishId: item
  };

  InventoryItem? getInventoryItem(String dishId) => _sharedInventoryMap[dishId];

  @override
  Future<List<InventoryItem>> getInventory() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _sharedInventoryMap.values.toList();
  }

  void addInventoryItem(InventoryItem item) {
    _sharedInventoryMap[item.dishId] = item;
  }

  @override
  Future<InventoryItem> updatePortionCount(String dishId, int newCount) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = _sharedInventoryMap[dishId];
    final updated = existing?.copyWith(
          availablePortions: newCount,
          isAvailable: newCount > 0,
          updatedAt: DateTime.now(),
        ) ??
        InventoryItem(
          dishId: dishId,
          dishName: dishId,
          category: 'Main Course',
          availablePortions: newCount,
          isAvailable: newCount > 0,
          updatedAt: DateTime.now(),
        );
    _sharedInventoryMap[dishId] = updated;
    return updated;
  }

  @override
  Future<InventoryItem> toggleAvailability(String dishId, bool isAvailable) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = _sharedInventoryMap[dishId];
    if (existing == null) {
      throw Exception('Dish inventory not found');
    }
    final updated = existing.copyWith(
      isAvailable: isAvailable,
      updatedAt: DateTime.now(),
    );
    _sharedInventoryMap[dishId] = updated;
    return updated;
  }
}
