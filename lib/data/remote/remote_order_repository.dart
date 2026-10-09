import '../../core/networking/api_client.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../models/receipt.dart';
import '../repositories/order_repository.dart';

class RemoteOrderRepository implements OrderRepository {
  final ApiClient apiClient;

  RemoteOrderRepository({required this.apiClient});

  @override
  Future<OrderModel> createOrder({
    required String idempotencyKey,
    required String customerName,
    String? customerNotes,
    required List<CartItem> items,
  }) async {
    final response = await apiClient.post(
      '/orders',
      headers: {'X-Idempotency-Key': idempotencyKey},
      data: {
        'idempotencyKey': idempotencyKey,
        'customerName': customerName,
        'customerNotes': customerNotes,
        'items': items.map((i) => i.toJson()).toList(),
      },
    );
    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    final response = await apiClient.get('/orders/$id');
    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<OrderModel>> getActiveOrders() async {
    final response = await apiClient.get('/orders/active');
    final list = response as List<dynamic>;
    return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<OrderModel>> getCompletedOrders() async {
    final response = await apiClient.get('/orders/completed');
    final list = response as List<dynamic>;
    return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<OrderModel> updateOrderStatus(String orderId, OrderStatus newStatus, {String? note}) async {
    final response = await apiClient.patch('/orders/$orderId/status', data: {
      'status': newStatus.name,
      if (note != null) 'note': note,
    });
    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ReceiptModel> getReceipt(String orderId) async {
    final response = await apiClient.get('/orders/$orderId/receipt');
    return ReceiptModel.fromJson(response as Map<String, dynamic>);
  }
}
