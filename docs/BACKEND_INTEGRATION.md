# LoopServe 3.0 — Backend Integration Contract & Guide

## 1. Overview
This document specifies the exact API contract, data schemas, headers, authentication, and WebSocket event protocol between the **LoopServe Frontend** (Flutter) and the **Backend Developer**.

All endpoints use standard JSON serialization. Prices are represented exclusively in **integer minor currency units (cents)** (e.g. `$24.50` = `2450`).

---

## 2. Base Configuration & Headers
- **Base REST API URL**: `http://<host>:<port>/api/v1` (Configurable via `--dart-define=API_URL=...`)
- **WebSocket Endpoint**: `ws://<host>:<port>/ws` (Configurable via `--dart-define=WS_URL=...`)
- **Headers**:
  - `Content-Type: application/json`
  - `X-Idempotency-Key: <uuid-string>` (Mandatory for order placement calls)

---

## 3. REST API Endpoints

### 3.1 Menu & Discovery
- **`GET /menu/dishes`**: Returns list of all available menu items.
- **`GET /menu/dishes/{id}`**: Returns single dish detail.
- **`GET /menu/categories`**: Returns list of category names (`["Main Course", "Wood-Fired Pizza", ...]`).
- **`GET /menu/search?q={query}&category={category}`**: Returns filtered dishes.

### 3.2 Order Management & Idempotency
- **`POST /orders`**
  - **Headers**: `X-Idempotency-Key: idemp-uuid-1234`
  - **Request Body**:
    ```json
    {
      "idempotencyKey": "idemp-uuid-1234",
      "customerName": "Alexander Wright",
      "customerNotes": "Extra crispy bacon",
      "items": [
        {
          "id": "cart_d1_g_portion:opt_p1",
          "dishId": "d1",
          "selectedOptions": { "g_portion": "opt_p1", "g_sauce": "opt_s1" },
          "selectedOptionNames": { "g_portion": "Classic Single", "g_sauce": "Secret Ember Sauce" },
          "extraPriceCents": 0,
          "unitPriceCents": 2450,
          "quantity": 1,
          "totalPriceCents": 2450
        }
      ]
    }
    ```
  - **Behavior**: If request with `X-Idempotency-Key` was previously received and processed, the server **MUST** return the existing order object without creating a duplicate record or deducting inventory twice.
  - **Error Responses**:
    - `409 Conflict`: Returned when requested portion count exceeds available inventory (`InventoryConflictFailure`).

- **`GET /orders/{id}`**: Returns specific order details.
- **`GET /orders/active`**: Returns active kitchen tickets (Status: `pending`, `accepted`, `preparing`, `ready`).
- **`GET /orders/completed`**: Returns finished orders (Status: `handedOver`, `cancelled`).

### 3.3 Staff Operations & Status Transitions
- **`PATCH /orders/{id}/status`**
  - **Request Body**:
    ```json
    {
      "status": "preparing", // "pending" | "accepted" | "preparing" | "ready" | "handedOver" | "cancelled"
      "note": "Optional staff note"
    }
    ```

### 3.4 Menu & Inventory Management
- **`GET /staff/inventory`**: Returns inventory portion counts for all dishes.
- **`PATCH /staff/inventory/{dishId}/portions`**
  - **Request Body**: `{ "availablePortions": 5 }`
- **`PATCH /staff/inventory/{dishId}/availability`**
  - **Request Body**: `{ "isAvailable": false }`

### 3.5 Receipts
- **`GET /orders/{id}/receipt`**: Returns authoritative receipt object.

---

## 4. WebSocket Realtime Protocol
Connect to `ws://<host>:<port>/ws`.

### Server -> Client Events
1. **`ORDER_CREATED`**: `{ "event": "ORDER_CREATED", "data": { "order": <OrderModel> }, "eventId": "evt-1" }`
2. **`ORDER_STATUS_CHANGED`**: `{ "event": "ORDER_STATUS_CHANGED", "data": { "orderId": "ord-101", "newStatus": "preparing" }, "eventId": "evt-2" }`
3. **`INVENTORY_UPDATED`**: `{ "event": "INVENTORY_UPDATED", "data": { "dishId": "d5", "availablePortions": 0, "isAvailable": false }, "eventId": "evt-3" }`

The frontend `RealtimeClient` handles event deduplication via `eventId` and automatic exponential reconnect.
