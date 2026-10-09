# LoopServe 3.0 — Track A Requirements Traceability Matrix

| Requirement # | Feature / Description | Code Location | Status |
|---|---|---|---|
| **REQ-1** | Customer Experience: Discover & Menu | `lib/features/home/discover_screen.dart`, `lib/features/menu/menu_screen.dart` | **Verified & Passed** |
| **REQ-2** | Interactive 3D Dish Viewport | `web/3d_viewer/index.html`, `lib/features/dish_studio/threed_viewer_widget.dart` | **Verified & Passed** |
| **REQ-3** | 3D Customization & Dynamic Price Sync | `lib/features/dish_studio/dish_detail_studio_screen.dart` | **Verified & Passed** |
| **REQ-4** | Shopping Cart with Option Preservation | `lib/features/cart/cart_screen.dart`, `lib/models/cart_item.dart` | **Verified & Passed** |
| **REQ-5** | Idempotent Order Checkout | `lib/features/checkout/checkout_screen.dart`, `lib/data/providers/app_providers.dart` | **Verified & Passed** |
| **REQ-6** | Real-Time Order Progress Tracking | `lib/features/orders/order_tracking_screen.dart` | **Verified & Passed** |
| **REQ-7** | Tax Receipts for Completed Orders | `lib/features/receipts/receipt_screen.dart` | **Verified & Passed** |
| **REQ-8** | Staff Operations Dashboard | `lib/features/staff_dashboard/staff_dashboard_screen.dart` | **Verified & Passed** |
| **REQ-9** | Staff Live Order Queue & Tickets | `lib/features/staff_orders/staff_order_queue_screen.dart` | **Verified & Passed** |
| **REQ-10** | Staff Portion & Inventory Management | `lib/features/inventory/staff_inventory_screen.dart` | **Verified & Passed** |
| **REQ-11** | Two Customers Competing Portion Conflict Safety | `lib/data/development/fixture_order_repository.dart`, `test/unit_test.dart` | **Verified & Passed** |
| **REQ-12** | Real-Time Client WS Abstraction | `lib/core/networking/websocket_client.dart` | **Verified & Passed** |
| **REQ-13** | Fixture vs Connected Backend Isolation Mode | `lib/app/configuration/app_config.dart`, `lib/core/widgets/mode_switcher_bar.dart` | **Verified & Passed** |
