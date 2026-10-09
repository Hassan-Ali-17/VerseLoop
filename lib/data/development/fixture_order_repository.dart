import '../repositories/order_repository.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../models/inventory_item.dart';
import '../../models/receipt.dart';
import '../../core/errors/failures.dart';
import 'fixture_data.dart';
import 'fixture_inventory_repository.dart';

class FixtureOrderRepository implements OrderRepository {
  final Map<String, OrderModel> _orders = {
    for (var o in FixtureData.sampleOrders) o.id: o
  };

  final Map<String, String> _idempotencyIndex = {
    for (var o in FixtureData.sampleOrders) o.idempotencyKey: o.id
  };

  final FixtureInventoryRepository? inventoryRepo;

  FixtureOrderRepository({this.inventoryRepo});

  int _orderCounter = 8044;

  @override
  Future<OrderModel> createOrder({
    required String idempotencyKey,
    required String customerName,
    String? customerNotes,
    required List<CartItem> items,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 1. Check Idempotency Key (Return existing if retried)
    if (_idempotencyIndex.containsKey(idempotencyKey)) {
      final existingOrderId = _idempotencyIndex[idempotencyKey]!;
      return _orders[existingOrderId]!;
    }

    // 2. Check inventory availability
    if (inventoryRepo != null) {
      final inventoryList = await inventoryRepo!.getInventory();
      for (final item in items) {
        final inv = inventoryList.firstWhere(
          (i) => i.dishId == item.dish.id,
          orElse: () => InventoryItem(
            dishId: item.dish.id,
            dishName: item.dish.name,
            category: item.dish.category,
            availablePortions: item.dish.stockCount,
            isAvailable: item.dish.isAvailable,
            updatedAt: DateTime.now(),
          ),
        );

        if (!inv.isAvailable || inv.availablePortions < item.quantity) {
          throw InventoryConflictFailure(
            dishName: item.dish.name,
            requestedCount: item.quantity,
            availableCount: inv.availablePortions,
          );
        }
      }

      // Decrement inventory portions
      for (final item in items) {
        final inv = inventoryList.firstWhere((i) => i.dishId == item.dish.id);
        await inventoryRepo!.updatePortionCount(
          item.dish.id,
          inv.availablePortions - item.quantity,
        );
      }
    }

    // 3. Create new Order
    final subtotalCents = items.fold<int>(0, (sum, item) => sum + item.totalPriceCents);
    const feeCents = 250;
    final totalCents = subtotalCents + feeCents;

    final orderId = 'ord-${DateTime.now().millisecondsSinceEpoch}';
    final orderNum = '${_orderCounter++}';
    final now = DateTime.now();

    final newOrder = OrderModel(
      id: orderId,
      idempotencyKey: idempotencyKey,
      orderNumber: orderNum,
      customerName: customerName.trim().isEmpty ? 'Guest Customer' : customerName.trim(),
      customerNotes: customerNotes,
      items: List.from(items),
      subtotalCents: subtotalCents,
      feeCents: feeCents,
      totalCents: totalCents,
      status: OrderStatus.pending,
      estimatedPrepMinutes: 20,
      createdAt: now,
      updatedAt: now,
      history: [
        OrderStatusLog(status: OrderStatus.pending, timestamp: now, note: 'Order placed by customer'),
      ],
    );

    _orders[orderId] = newOrder;
    _idempotencyIndex[idempotencyKey] = orderId;

    return newOrder;
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _orders[id];
  }

  @override
  Future<List<OrderModel>> getActiveOrders() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _orders.values
        .where((o) => o.status != OrderStatus.handedOver && o.status != OrderStatus.cancelled)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<OrderModel>> getCompletedOrders() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _orders.values
        .where((o) => o.status == OrderStatus.handedOver || o.status == OrderStatus.cancelled)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<OrderModel> updateOrderStatus(String orderId, OrderStatus newStatus, {String? note}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = _orders[orderId];
    if (existing == null) {
      throw const ServerFailure('Order not found', 404);
    }

    if (!existing.status.canTransitionTo(newStatus)) {
      throw InvalidTransitionFailure(
        currentStatus: existing.status.label,
        attemptedStatus: newStatus.label,
      );
    }

    final now = DateTime.now();
    final updatedHistory = List<OrderStatusLog>.from(existing.history)
      ..add(OrderStatusLog(status: newStatus, timestamp: now, note: note));

    final updated = existing.copyWith(
      status: newStatus,
      updatedAt: now,
      history: updatedHistory,
    );

    _orders[orderId] = updated;
    return updated;
  }

  @override
  Future<ReceiptModel> getReceipt(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final order = _orders[orderId];
    if (order == null) {
      throw const ServerFailure('Order not found for receipt', 404);
    }
    return ReceiptModel.fromOrder(order);
  }
}
