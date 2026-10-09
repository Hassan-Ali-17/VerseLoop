import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/configuration/app_config.dart';
import '../core/widgets/mode_switcher_bar.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/dish_studio/dish_detail_studio_screen.dart';
import '../features/home/discover_screen.dart';
import '../features/inventory/staff_inventory_screen.dart';
import '../features/menu/menu_screen.dart';
import '../features/orders/order_tracking_screen.dart';
import '../features/receipts/receipt_screen.dart';
import '../features/staff_dashboard/staff_dashboard_screen.dart';
import '../features/staff_orders/staff_completed_orders_screen.dart';
import '../features/staff_orders/staff_order_queue_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: Column(
            children: [
              const ModeSwitcherBar(),
              Expanded(child: child),
            ],
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return AppConfig.currentRole == UserRole.customer
                ? const DiscoverScreen()
                : const StaffDashboardScreen();
          },
        ),
        GoRoute(
          path: '/discover',
          builder: (context, state) => const DiscoverScreen(),
        ),
        GoRoute(
          path: '/menu',
          builder: (context, state) => const MenuScreen(),
        ),
        GoRoute(
          path: '/dish/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? 'd1';
            return DishDetailStudioScreen(dishId: id);
          },
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/orders/tracking/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? 'ord-101';
            return OrderTrackingScreen(orderId: id);
          },
        ),
        GoRoute(
          path: '/receipt/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? 'ord-101';
            return ReceiptScreen(orderId: id);
          },
        ),

        // Staff Experience Routes
        GoRoute(
          path: '/staff/dashboard',
          builder: (context, state) => const StaffDashboardScreen(),
        ),
        GoRoute(
          path: '/staff/queue',
          builder: (context, state) => const StaffOrderQueueScreen(),
        ),
        GoRoute(
          path: '/staff/inventory',
          builder: (context, state) => const StaffInventoryScreen(),
        ),
        GoRoute(
          path: '/staff/completed',
          builder: (context, state) => const StaffCompletedOrdersScreen(),
        ),
      ],
    ),
  ],
);
