import 'package:flutter_test/flutter_test.dart';
import 'package:loopserve/core/formatting/currency_formatter.dart';
import 'package:loopserve/core/errors/failures.dart';
import 'package:loopserve/data/development/fixture_data.dart';
import 'package:loopserve/data/development/fixture_inventory_repository.dart';
import 'package:loopserve/data/development/fixture_order_repository.dart';
import 'package:loopserve/models/cart_item.dart';
import 'package:loopserve/models/order.dart';

void main() {
  group('1. Currency & Pricing Integrity Tests', () {
    test('CurrencyFormatter accurately formats integer minor currency units (cents)', () {
      expect(CurrencyFormatter.formatCents(2450), '\$24.50');
      expect(CurrencyFormatter.formatCents(0), '\$0.00');
      expect(CurrencyFormatter.formatCents(4500), '\$45.00');
    });

    test('dollarsToCents converts double without floating point rounding errors', () {
      expect(CurrencyFormatter.dollarsToCents(24.50), 2450);
      expect(CurrencyFormatter.dollarsToCents(28.00), 2800);
    });
  });

  group('2. Idempotency & Order Submission Tests', () {
    test('Retrying order with exact same idempotency key returns existing order without creating duplicate', () async {
      final inventoryRepo = FixtureInventoryRepository();
      final orderRepo = FixtureOrderRepository(inventoryRepo: inventoryRepo);

      final sampleDish = FixtureData.sampleDishes[0];
      final items = [
        CartItem(
          id: 'c_test1',
          dish: sampleDish,
          selectedOptions: {'g_portion': 'opt_p1'},
          selectedOptionNames: {'g_portion': 'Classic Single'},
          extraPriceCents: 0,
          quantity: 1,
        )
      ];

      const idempotencyKey = 'idempotency-key-uuid-12345';

      // First attempt
      final order1 = await orderRepo.createOrder(
        idempotencyKey: idempotencyKey,
        customerName: 'Test Customer',
        items: items,
      );

      // Second attempt (retry)
      final order2 = await orderRepo.createOrder(
        idempotencyKey: idempotencyKey,
        customerName: 'Test Customer',
        items: items,
      );

      expect(order1.id, order2.id);
      expect(order1.orderNumber, order2.orderNumber);
      expect(order1.idempotencyKey, idempotencyKey);
    });
  });

  group('3. Inventory Safety & Portion Competition Tests', () {
    test('Attempting to purchase sold-out dish throws InventoryConflictFailure', () async {
      final inventoryRepo = FixtureInventoryRepository();
      final orderRepo = FixtureOrderRepository(inventoryRepo: inventoryRepo);

      // Dish d5 has stock count 1 in fixture
      final dessertDish = FixtureData.sampleDishes[4];

      final items = [
        CartItem(
          id: 'c_test_dessert',
          dish: dessertDish,
          selectedOptions: {},
          selectedOptionNames: {},
          extraPriceCents: 0,
          quantity: 2, // Requesting 2 portions when only 1 available!
        )
      ];

      expect(
        () => orderRepo.createOrder(
          idempotencyKey: 'key-sold-out-test',
          customerName: 'Customer B',
          items: items,
        ),
        throwsA(isA<InventoryConflictFailure>()),
      );
    });
  });

  group('4. Order Lifecycle & Status Transition Rules', () {
    test('OrderStatus transition checks enforce strict valid rules', () {
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.accepted), true);
      expect(OrderStatus.accepted.canTransitionTo(OrderStatus.preparing), true);
      expect(OrderStatus.preparing.canTransitionTo(OrderStatus.ready), true);
      expect(OrderStatus.ready.canTransitionTo(OrderStatus.handedOver), true);

      // Invalid jump from pending directly to handedOver
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.handedOver), false);
      // Terminal state handedOver cannot transition
      expect(OrderStatus.handedOver.canTransitionTo(OrderStatus.preparing), false);
    });
  });
}
