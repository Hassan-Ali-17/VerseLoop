import '../../models/inventory_item.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getInventory();
  Future<InventoryItem> updatePortionCount(String dishId, int newCount);
  Future<InventoryItem> toggleAvailability(String dishId, bool isAvailable);
}
