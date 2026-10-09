import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../app/configuration/app_config.dart';
import '../../core/networking/api_client.dart';
import '../../core/networking/websocket_client.dart';
import '../../models/cart_item.dart';
import '../../models/dish.dart';
import '../../models/inventory_item.dart';
import '../../models/order.dart';
import '../development/fixture_inventory_repository.dart';
import '../development/fixture_menu_repository.dart';
import '../development/fixture_order_repository.dart';
import '../remote/remote_inventory_repository.dart';
import '../remote/remote_menu_repository.dart';
import '../remote/remote_order_repository.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/menu_repository.dart';
import '../repositories/order_repository.dart';

// App Configuration & Role Providers using Notifier
class AppModeNotifier extends Notifier<AppMode> {
  @override
  AppMode build() => AppConfig.currentMode;
  void setMode(AppMode mode) {
    AppConfig.setMode(mode);
    state = mode;
  }
}

final appModeProvider = NotifierProvider<AppModeNotifier, AppMode>(AppModeNotifier.new);

class UserRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => AppConfig.currentRole;
  void setRole(UserRole role) {
    AppConfig.setRole(role);
    state = role;
  }
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole>(UserRoleNotifier.new);

// Singletons / Clients
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  // React to mode switch between Fixture and Connected
  final mode = ref.watch(appModeProvider);
  final client = RealtimeClient();
  client.connect();
  ref.onDispose(() => client.dispose());
  return client;
});

// Repositories (Swapped dynamically based on AppMode)
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.fixture) {
    return _singletonFixtureInventory;
  } else {
    return RemoteInventoryRepository(apiClient: ref.watch(apiClientProvider));
  }
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.fixture) {
    return FixtureMenuRepository();
  } else {
    return RemoteMenuRepository(apiClient: ref.watch(apiClientProvider));
  }
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final mode = ref.watch(appModeProvider);
  if (mode == AppMode.fixture) {
    return _singletonFixtureOrder;
  } else {
    return RemoteOrderRepository(apiClient: ref.watch(apiClientProvider));
  }
});

final _singletonFixtureInventory = FixtureInventoryRepository();
final _singletonFixtureOrder = FixtureOrderRepository(inventoryRepo: _singletonFixtureInventory);

// ----------------------------------------------------
// CART STATE MANAGEMENT (Notifier)
// ----------------------------------------------------
class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  int get subtotalCents => items.fold(0, (sum, i) => sum + i.totalPriceCents);
  int get serviceFeeCents => items.isEmpty ? 0 : 250;
  int get totalCents => subtotalCents + serviceFeeCents;

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addItem({
    required Dish dish,
    required Map<String, String> selectedOptions,
    required Map<String, String> selectedOptionNames,
    required int extraPriceCents,
    int quantity = 1,
  }) {
    final newItemId = 'cart_${dish.id}_${selectedOptions.entries.map((e) => '${e.key}:${e.value}').join('_')}';
    final existingIndex = state.items.indexWhere((i) => i.id == newItemId);

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updatedList = List<CartItem>.from(state.items);
      updatedList[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = CartItem(
        id: newItemId,
        dish: dish,
        selectedOptions: selectedOptions,
        selectedOptionNames: selectedOptionNames,
        extraPriceCents: extraPriceCents,
        quantity: quantity,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(cartItemId);
      return;
    }
    final updatedList = state.items.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updatedList);
  }

  void removeItem(String cartItemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != cartItemId).toList(),
    );
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

// ----------------------------------------------------
// CHECKOUT STATE MANAGEMENT (Notifier)
// ----------------------------------------------------
class CheckoutState {
  final String idempotencyKey;
  final bool isSubmitting;
  final String? errorMessage;
  final OrderModel? confirmedOrder;

  const CheckoutState({
    required this.idempotencyKey,
    this.isSubmitting = false,
    this.errorMessage,
    this.confirmedOrder,
  });

  CheckoutState copyWith({
    String? idempotencyKey,
    bool? isSubmitting,
    String? errorMessage,
    OrderModel? confirmedOrder,
  }) {
    return CheckoutState(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      confirmedOrder: confirmedOrder ?? this.confirmedOrder,
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  static const _uuid = Uuid();

  @override
  CheckoutState build() => CheckoutState(idempotencyKey: 'idemp-${_uuid.v4()}');

  void resetKey() {
    state = CheckoutState(idempotencyKey: 'idemp-${_uuid.v4()}');
  }

  Future<bool> submitOrder({
    required String customerName,
    String? customerNotes,
  }) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Cart is empty. Please add dishes before placing an order.',
      );
      return false;
    }

    final orderRepo = ref.read(orderRepositoryProvider);

    try {
      final newOrder = await orderRepo.createOrder(
        idempotencyKey: state.idempotencyKey,
        customerName: customerName,
        customerNotes: customerNotes,
        items: cartState.items,
      );

      state = state.copyWith(
        isSubmitting: false,
        confirmedOrder: newOrder,
      );

      ref.read(cartProvider.notifier).clearCart();
      ref.read(activeOrdersProvider.notifier).refreshOrders();
      ref.read(staffOrdersProvider.notifier).refreshOrders();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

// ----------------------------------------------------
// ORDERS PROVIDERS (AsyncNotifier)
// ----------------------------------------------------
class ActiveOrdersNotifier extends AsyncNotifier<List<OrderModel>> {
  StreamSubscription? _wsSub;

  @override
  Future<List<OrderModel>> build() async {
    final repo = ref.watch(orderRepositoryProvider);
    final wsClient = ref.watch(realtimeClientProvider);

    _wsSub?.cancel();
    _wsSub = wsClient.events.listen((event) {
      if (event.event == 'ORDER_CREATED' || event.event == 'ORDER_STATUS_CHANGED') {
        refreshOrders();
      }
    });
    ref.onDispose(() => _wsSub?.cancel());

    return await repo.getActiveOrders();
  }

  Future<void> refreshOrders() async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      final list = await repo.getActiveOrders();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    final repo = ref.read(orderRepositoryProvider);
    await repo.updateOrderStatus(orderId, status);
    await refreshOrders();
  }
}

final activeOrdersProvider = AsyncNotifierProvider<ActiveOrdersNotifier, List<OrderModel>>(ActiveOrdersNotifier.new);
final staffOrdersProvider = AsyncNotifierProvider<ActiveOrdersNotifier, List<OrderModel>>(ActiveOrdersNotifier.new);

// ----------------------------------------------------
// INVENTORY STATE PROVIDER (AsyncNotifier)
// ----------------------------------------------------
class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  StreamSubscription? _wsSub;

  @override
  Future<List<InventoryItem>> build() async {
    final repo = ref.watch(inventoryRepositoryProvider);
    final wsClient = ref.watch(realtimeClientProvider);

    _wsSub?.cancel();
    _wsSub = wsClient.events.listen((event) {
      if (event.event == 'INVENTORY_UPDATED') {
        refreshInventory();
      }
    });
    ref.onDispose(() => _wsSub?.cancel());

    return await repo.getInventory();
  }

  Future<void> refreshInventory() async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final list = await repo.getInventory();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePortions(String dishId, int newCount) async {
    final repo = ref.read(inventoryRepositoryProvider);
    await repo.updatePortionCount(dishId, newCount);
    await refreshInventory();
  }

  Future<void> toggleAvailability(String dishId, bool isAvailable) async {
    final repo = ref.read(inventoryRepositoryProvider);
    await repo.toggleAvailability(dishId, isAvailable);
    await refreshInventory();
  }
}

final inventoryProvider = AsyncNotifierProvider<InventoryNotifier, List<InventoryItem>>(InventoryNotifier.new);
