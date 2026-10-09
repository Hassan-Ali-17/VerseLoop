import '../../core/networking/api_client.dart';
import '../../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class RemoteInventoryRepository implements InventoryRepository {
  final ApiClient apiClient;

  RemoteInventoryRepository({required this.apiClient});

  @override
  Future<List<InventoryItem>> getInventory() async {
    final response = await apiClient.get('/staff/inventory');
    final list = response as List<dynamic>;
    return list.map((e) => InventoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<InventoryItem> updatePortionCount(String dishId, int newCount) async {
    final response = await apiClient.patch('/staff/inventory/$dishId/portions', data: {
      'availablePortions': newCount,
    });
    return InventoryItem.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<InventoryItem> toggleAvailability(String dishId, bool isAvailable) async {
    final response = await apiClient.patch('/staff/inventory/$dishId/availability', data: {
      'isAvailable': isAvailable,
    });
    return InventoryItem.fromJson(response as Map<String, dynamic>);
  }
}
