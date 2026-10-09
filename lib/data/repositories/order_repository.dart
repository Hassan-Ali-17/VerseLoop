import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../models/receipt.dart';

abstract class OrderRepository {
  Future<OrderModel> createOrder({
    required String idempotencyKey,
    required String customerName,
    String? customerNotes,
    required List<CartItem> items,
  });

  Future<OrderModel?> getOrderById(String id);
  Future<List<OrderModel>> getActiveOrders();
  Future<List<OrderModel>> getCompletedOrders();
  Future<OrderModel> updateOrderStatus(String orderId, OrderStatus newStatus, {String? note});
  Future<ReceiptModel> getReceipt(String orderId);
}
