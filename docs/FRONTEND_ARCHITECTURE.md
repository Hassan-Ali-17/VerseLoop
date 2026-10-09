# LoopServe 3.0 — Frontend Architecture Specification

## 1. Architectural Philosophy
LoopServe 3.0 is built as a single, high-performance Flutter codebase implementing **EMBER**, a fine-dining visual concept.

The system strictly decouples:
- **UI Rendering Layer** (Flutter Widgets & Design Tokens)
- **State Management Layer** (Riverpod `Notifier` & `AsyncNotifier`)
- **Domain Models & Pricing Logic** (Cents-based integer math)
- **Data Access & Integration Layer** (Abstract Repositories, Fixtures, & Remote Clients)

---

## 2. Directory Map
```
lib/
├── app/
│   ├── app.dart                   # Root MaterialApp & Theme
│   ├── router.dart                # Declarative GoRouter configuration
│   ├── configuration/
│   │   └── app_config.dart        # Mode (Fixture/Connected) & Role config
│   └── theme/
│       └── ember_theme.dart       # EMBER design system tokens
├── core/
│   ├── errors/failures.dart       # Typed failure definitions
│   ├── formatting/
│   │   ├── currency_formatter.dart# Cents to dollar string formatter
│   │   └── date_formatter.dart    # Time & date formatters
│   ├── networking/
│   │   ├── api_client.dart        # Dio HTTP REST wrapper
│   │   └── websocket_client.dart  # RealtimeClient WS abstraction
│   └── widgets/                   # Reusable components
├── data/
│   ├── development/               # Fixture data & standalone repositories
│   ├── providers/                 # Riverpod application state providers
│   ├── remote/                    # Production API repositories
│   └── repositories/              # Repository interfaces
├── features/                      # Application feature screens
│   ├── home/                      # Discover Screen
│   ├── menu/                      # Menu Screen
│   ├── dish_studio/               # Interactive 3D Studio & Three.js Bridge
│   ├── cart/                      # Shopping Cart
│   ├── checkout/                  # Idempotent Checkout
│   ├── orders/                    # Live Order Tracking
│   ├── receipts/                  # Tax Receipts
│   ├── staff_dashboard/           # Operations Console
│   ├── staff_orders/              # Kitchen Live Queue & Completed Orders
│   └── inventory/                 # Portion & Availability Management
└── main.dart                      # Application entry point
```

---

## 3. Interactive 3D Studio Architecture
The 3D Studio relies on a hybrid Three.js WebGL rendering engine (`web/3d_viewer/index.html`) embedded into Flutter via HTML Element View.

- **Scene Lighting**: Key Ember directional light, cool fill light, and specular spot lighting.
- **Procedural Mesh Models**: High-detail 3D geometry for Burger, Pizza, Steak, Ramen, and Lava Cake.
- **Communication Bridge**: `postMessage` protocol passing `LOAD_DISH`, `UPDATE_CUSTOMIZATION`, and `RESET_CAMERA` events.
