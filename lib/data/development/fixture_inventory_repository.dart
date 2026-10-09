import '../repositories/inventory_repository.dart';
import '../../models/inventory_item.dart';
import 'fixture_data.dart';

class FixtureInventoryRepository implements InventoryRepository {
  final Map<String, InventoryItem> _inventoryMap = {
    for (var item in FixtureData.initialInventory) item.dishId: item
  };

  @override
  Future<List<InventoryItem>> getInventory() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _inventoryMap.values.toList();
  }

  @override
  Future<InventoryItem> updatePortionCount(String dishId, int newCount) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = _inventoryMap[dishId];
    if (existing == null) {
      throw Exception('Dish inventory not found');
    }
    final updated = existing.copyWith(
      availablePortions: newCount,
      isAvailable: newCount > 0,
      updatedAt: DateTime.now(),
    );
    _inventoryMap[dishId] = updated;
    return updated;
  }

  @override
  Future<InventoryItem> toggleAvailability(String dishId, bool isAvailable) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = _inventoryMap[dishId];
    if (existing == null) {
      throw Exception('Dish inventory not found');
    }
    final updated = existing.copyWith(
      isAvailable: isAvailable,
      updatedAt: DateTime.now(),
    );
    _inventoryMap[dishId] = updated;
    return updated;
  }
}
