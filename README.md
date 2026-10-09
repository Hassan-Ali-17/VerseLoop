# LoopServe 3.0 — Track A: Advanced Restaurant Operations System

> **Loopverse 3.0 Virtual App Development Challenge**  
> Visual Concept: **EMBER** — Modern Fine Dining Meets Cinematic Digital Craftsmanship

---

## 🌟 Architecture & System Overview

LoopServe 3.0 is a full-stack, enterprise-grade fine dining restaurant operations system combining an ambient customer discovery & ordering journey with a real-time kitchen display system (KDS) and inventory console.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Flutter Client (Web / Desktop / Mobile)              │
│  - Customer: 3D Ambient Studio, Discover, Menu, Cart, Realtime Tracker │
│  - Staff Console: PIN Gate (1234), Live Order Queue, Portion Inventory │
└───────────────────────▲───────────────────────▲────────────────────────┘
                        │ HTTP / REST (/api/v1) │ WebSocket (/ws)
                        ▼                       ▼
┌────────────────────────────────────────────────────────────────────────┐
│                 FastAPI Python Backend (Port 8080)                     │
│  - Non-blocking real-time event broadcasting (ws_hub.broadcast_nowait) │
│  - Idempotent order processing & inventory concurrency lock guard      │
│  - Asynchronous HTTP connection pool (httpx.AsyncClient)               │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ PostgREST / JSON
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   Supabase Cloud PostgreSQL Database                   │
│  - tables: `dishes`, `inventory`, `orders`, `order_items`              │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start Guide

### Prerequisites
- **Flutter SDK**: `^3.44.4` (Dart `^3.12.2`)
- **Python**: `3.10+`
- **Supabase Cloud Project**: Configured with PostgREST tables (`dishes`, `inventory`, `orders`, `order_items`)

---

### 1. Environment Configuration

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://<your-project-id>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<your-supabase-service-role-key>
SUPABASE_ANON_KEY=<your-supabase-anon-key>
HOST=0.0.0.0
PORT=8080
API_PREFIX=/api/v1
```

---

### 2. Run Backend Server (FastAPI + Supabase)

Install Python dependencies:

```bash
pip install -r backend/requirements.txt
```

Start the live backend server:

```bash
python run_backend.py
```
- **REST API Base**: `http://localhost:8080/api/v1`
- **Realtime WebSocket**: `ws://localhost:8080/ws`
- **Interactive OpenAPI Docs**: `http://localhost:8080/docs`
- **Health Verification**: `http://localhost:8080/api/v1/health`

#### Run Automated Backend Concurrency & Idempotency Tests:
Validates non-negotiable constraints, race condition prevention on dish `d5`, idempotency keys, and cancellation handling:

```bash
python -m backend.test_backend
```

---

### 3. Run Frontend Application (Flutter)

Fetch dependencies:

```bash
flutter pub get
```

Launch the application:

```bash
# Run in Chrome Web Browser
flutter run -d chrome

# Run Windows Desktop application
flutter run -d windows
```

To configure custom backend endpoints during build or launch:

```bash
flutter run -d chrome --dart-define=API_URL=http://localhost:8080/api/v1 --dart-define=WS_URL=ws://localhost:8080/ws
```

---

### 4. Run Automated Flutter Test Suite

Execute the complete unit and widget test suite:

```bash
flutter test
```

All 6 automated tests validate:
1. Minor currency integer conversion (pricing in minor cents).
2. Dollars-to-cents rounding integrity.
3. Order idempotency key safety.
4. Sold-out inventory conflict rejection.
5. LoopServeApp initial boot & widget tree render.

---

## 🛠️ Operating Modes & Presentation Controls

A persistent, responsive **Mode Switcher Bar** is rendered at the top of the viewport:

### 1. Environment Modes
- **Connected Backend Mode (Default)**: Connects to the live FastAPI server (`http://localhost:8080/api/v1`), Supabase Cloud PostgreSQL, and WebSocket event stream (`ws://localhost:8080/ws`).
- **Development Fixture Mode**: Uses deterministic in-memory fixtures (`fixture_data.dart`). Allows completely offline demonstration without requiring an active backend or internet connection.

### 2. Role Switcher (`Customer` vs `Staff`)
- **🍽️ Customer View**: Browse curated menu, customize portions in the 3D Dish Detail Studio, manage cart, place orders, and track live status.
- **⚡ Staff Operations**: Access the kitchen display system (KDS), manage active tickets, adjust prep times, toggle portion counts, and inspect historical receipts.
- **🔐 Staff Passcode Gate**: Switching from Customer to Staff mode requires a security passcode dialog (Default PIN: `1234`).

### 3. Responsive Mobile View
- Automatically adapts on screens `< 650px` into a clean **2-line touch-friendly layout**:
  - **Line 1**: `🍽️ Customer` vs `⚡ Staff` segmented switcher + `Reset Test Data` button.
  - **Line 2**: Real-time connection badge (`LIVE`, `OFFLINE`, `SYNCING`) + `Connected` vs `Offline` mode toggle.

---

## ⚡ Real-Time WebSocket Protocol

The backend and frontend communicate bi-directionally over `ws://<host>:<port>/ws`:

| Event Name | Direction | Description |
| :--- | :--- | :--- |
| `ORDER_CREATED` | Server ➔ Clients | Dispatched on new customer order placement. Notifies kitchen KDS immediately. |
| `ORDER_STATUS_CHANGED` | Server ➔ Clients | Dispatched on ticket progression (`pending` ➔ `accepted` ➔ `preparing` ➔ `ready` ➔ `handedOver` ➔ `cancelled`). Synchronizes customer tracker. |
| `INVENTORY_UPDATED` | Server ➔ Clients | Dispatched when portions are adjusted or marked sold out. Syncs catalog across all screens. |
| `PING` / `PONG` | Bi-directional | Heartbeat keep-alive to maintain connection health through network fluctuations. |

---

## 📚 Documentation Index
- [`docs/BACKEND_INTEGRATION.md`](file:///d:/loopverse/docs/BACKEND_INTEGRATION.md): Complete backend integration guide & API contract.
- [`docs/FRONTEND_ARCHITECTURE.md`](file:///d:/loopverse/docs/FRONTEND_ARCHITECTURE.md): State flow, Riverpod providers, & 3D canvas architecture.
- [`docs/REQUIREMENTS_TRACEABILITY.md`](file:///d:/loopverse/docs/REQUIREMENTS_TRACEABILITY.md): Mapping of all Track A prompt requirements to code.
- [`docs/DEVELOPMENT_STATUS.md`](file:///d:/loopverse/docs/DEVELOPMENT_STATUS.md): Current status matrix of all requirements.
- [`docs/TEST_REPORT.md`](file:///d:/loopverse/docs/TEST_REPORT.md): Automated test execution report.
- [`docs/DEMO_SCRIPT.md`](file:///d:/loopverse/docs/DEMO_SCRIPT.md): Step-by-step hackathon presentation guide.
