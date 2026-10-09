import random
import uuid
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel, Field

from .menu import format_dish
from ..supabase_client import supabase
from ..websocket_hub import ws_hub

router = APIRouter(prefix="/orders", tags=["Orders & Idempotency"])

class OrderItemPayload(BaseModel):
    id: Optional[str] = None
    dishId: Optional[str] = None
    dish: Optional[Dict[str, Any]] = None
    selectedOptions: Dict[str, str] = Field(default_factory=dict)
    selectedOptionNames: Dict[str, str] = Field(default_factory=dict)
    extraPriceCents: int = 0
    unitPriceCents: Optional[int] = None
    quantity: int = 1
    totalPriceCents: Optional[int] = None

class CreateOrderPayload(BaseModel):
    idempotencyKey: str
    customerName: str
    customerNotes: Optional[str] = None
    items: List[Dict[str, Any]]

class UpdateStatusPayload(BaseModel):
    status: str
    note: Optional[str] = None

def format_order(
    row: Dict[str, Any],
    history: Optional[List[Dict[str, Any]]] = None,
    dish_map: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Format database row to camelCase matching Flutter OrderModel."""
    hist = []
    if history:
        for h in history:
            hist.append({
                "status": h.get("status"),
                "timestamp": h.get("timestamp"),
                "note": h.get("note"),
            })
    elif "history" in row and isinstance(row["history"], list):
        hist = row["history"]

    raw_items = row.get("items") or []
    formatted_items = []
    for it in raw_items:
        it_copy = dict(it)
        dish = it_copy.get("dish")
        d_id = it_copy.get("dishId") or (dish.get("id") if isinstance(dish, dict) else None)
        if (not dish or not dish.get("name") or not dish.get("category")) and dish_map and d_id in dish_map:
            it_copy["dish"] = dish_map[d_id]
        elif not dish:
            it_copy["dish"] = {
                "id": d_id or "d1",
                "name": "Ember Gourmet Dish",
                "category": "Main Course",
                "description": "",
                "basePriceCents": it_copy.get("unitPriceCents", 2000),
                "imageUrl": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop",
                "model3dId": d_id or "d1",
                "isAvailable": True,
                "stockCount": 10,
                "isFeatured": False,
                "ingredients": [],
                "customizationGroups": [],
            }
        it_copy.setdefault("id", f"item-{d_id or '1'}")
        it_copy.setdefault("dishId", d_id)
        it_copy.setdefault("selectedOptions", {})
        it_copy.setdefault("selectedOptionNames", {})
        it_copy.setdefault("extraPriceCents", 0)
        it_copy.setdefault("quantity", 1)
        it_copy.setdefault("unitPriceCents", it_copy.get("dish", {}).get("basePriceCents", 2000))
        it_copy.setdefault("totalPriceCents", it_copy["unitPriceCents"] * it_copy["quantity"])
        formatted_items.append(it_copy)

    return {
        "id": row.get("id"),
        "idempotencyKey": row.get("idempotency_key"),
        "orderNumber": str(row.get("order_number")),
        "customerName": row.get("customer_name"),
        "customerNotes": row.get("customer_notes"),
        "items": formatted_items,
        "subtotalCents": row.get("subtotal_cents", 0),
        "feeCents": row.get("fee_cents", 250),
        "totalCents": row.get("total_cents", 0),
        "status": row.get("status", "pending"),
        "estimatedPrepMinutes": row.get("estimated_prep_minutes", 20),
        "createdAt": row.get("created_at"),
        "updatedAt": row.get("updated_at"),
        "history": hist,
    }

@router.post("")
async def create_order(
    payload: CreateOrderPayload,
    x_idempotency_key: Optional[str] = Header(None, alias="X-Idempotency-Key"),
):
    """
    Atomic Order Creation with Strict Idempotency & Concurrency Locking:
    - Replays prior order if idempotency key exists
    - Row-level lock on inventory (prevents selling past 0)
    - Returns 409 Conflict if dish stock is exhausted
    - Broadcasts live ORDER_CREATED and INVENTORY_UPDATED events
    """
    idemp_key = x_idempotency_key or payload.idempotencyKey
    if not idemp_key:
        raise HTTPException(status_code=400, detail="Missing idempotency key")

    if not payload.items:
        raise HTTPException(status_code=400, detail="Cart is empty")

    # 1. Fetch dishes to resolve metadata and calculate server-side authoritative pricing
    dish_rows = await supabase.get("dishes", {"select": "*"})
    dish_map = {d["id"]: format_dish(d) for d in dish_rows}

    subtotal = 0
    clean_items = []
    for item in payload.items:
        dish_info = item.get("dish") or {}
        dish_id = item.get("dishId") or dish_info.get("id")
        if not dish_id or dish_id not in dish_map:
            raise HTTPException(status_code=400, detail=f"Valid dishId is required (found: '{dish_id}')")

        full_dish = dish_map[dish_id]
        qty = int(item.get("quantity", 1))
        extra_price = int(item.get("extraPriceCents", 0))
        unit_price = full_dish["basePriceCents"] + extra_price
        total_price = unit_price * qty
        subtotal += total_price

        clean_item = {
            "id": item.get("id") or f"cart_{dish_id}_{uuid.uuid4().hex[:4]}",
            "dishId": dish_id,
            "dish": full_dish,
            "selectedOptions": item.get("selectedOptions") or {},
            "selectedOptionNames": item.get("selectedOptionNames") or {},
            "extraPriceCents": extra_price,
            "unitPriceCents": unit_price,
            "quantity": qty,
            "totalPriceCents": total_price,
        }
        clean_items.append(clean_item)

    fee = 250
    total = subtotal + fee
    order_id = f"ord-{uuid.uuid4().hex[:8]}"
    order_number = str(random.randint(8050, 9999))

    # 2. Invoke atomic stored procedure
    rpc_params = {
        "p_idempotency_key": idemp_key,
        "p_order_id": order_id,
        "p_order_number": order_number,
        "p_customer_name": payload.customerName,
        "p_customer_notes": payload.customerNotes or "",
        "p_items": clean_items,
        "p_subtotal_cents": subtotal,
        "p_fee_cents": fee,
        "p_total_cents": total,
        "p_estimated_prep_minutes": 20,
    }

    try:
        confirmed_order = await supabase.rpc("place_order_atomic", rpc_params)
    except Exception as e:
        error_msg = str(e)
        if "INSUFFICIENT_STOCK" in error_msg:
            # Non-negotiable constraint: 409 Conflict when portion is sold out
            raise HTTPException(
                status_code=409,
                detail="One or more items in your cart are no longer available in sufficient quantity. Portion sold out.",
            )
        raise HTTPException(status_code=400, detail=f"Order creation failed: {error_msg}")

    # 3. Broadcast real-time events to Staff & Customer dashboards in background
    ws_hub.broadcast_event_nowait("ORDER_CREATED", {"order": confirmed_order})

    # Broadcast inventory updates asynchronously without stalling HTTP response
    import asyncio
    async def _async_inv_broadcast():
        for item in clean_items:
            dish_id = item["dishId"]
            inv = await supabase.get_one("inventory", {"dish_id": f"eq.{dish_id}", "select": "*"})
            if inv:
                await ws_hub.broadcast_event(
                    "INVENTORY_UPDATED",
                    {
                        "dishId": dish_id,
                        "availablePortions": inv.get("available_portions", 0),
                        "isAvailable": inv.get("is_available", False),
                    },
                )
    asyncio.create_task(_async_inv_broadcast())

    return confirmed_order

@router.get("/active")
async def get_active_orders():
    """Retrieve active kitchen orders (pending, accepted, preparing, ready)."""
    rows = await supabase.get(
        "orders",
        {"status": "in.(pending,accepted,preparing,ready)", "order": "created_at.desc", "select": "*"},
    )
    if not rows:
        return []

    dish_rows = await supabase.get("dishes", {"select": "*"})
    dish_map = {d["id"]: format_dish(d) for d in dish_rows}

    order_ids = [r["id"] for r in rows]
    all_logs = await supabase.get(
        "order_status_logs",
        {"order_id": f"in.({','.join(order_ids)})", "order": "timestamp.asc", "select": "*"},
    )
    logs_by_order: Dict[str, List[Dict[str, Any]]] = {}
    for log in all_logs:
        logs_by_order.setdefault(log["order_id"], []).append(log)

    return [format_order(r, logs_by_order.get(r["id"], []), dish_map) for r in rows]

@router.get("/completed")
async def get_completed_orders():
    """Retrieve finished orders (handedOver, cancelled)."""
    rows = await supabase.get(
        "orders",
        {"status": "in.(handedOver,cancelled)", "order": "updated_at.desc", "select": "*"},
    )
    if not rows:
        return []

    dish_rows = await supabase.get("dishes", {"select": "*"})
    dish_map = {d["id"]: format_dish(d) for d in dish_rows}

    order_ids = [r["id"] for r in rows]
    all_logs = await supabase.get(
        "order_status_logs",
        {"order_id": f"in.({','.join(order_ids)})", "order": "timestamp.asc", "select": "*"},
    )
    logs_by_order: Dict[str, List[Dict[str, Any]]] = {}
    for log in all_logs:
        logs_by_order.setdefault(log["order_id"], []).append(log)

    return [format_order(r, logs_by_order.get(r["id"], []), dish_map) for r in rows]

@router.get("/{order_id}")
async def get_order_by_id(order_id: str):
    """Retrieve specific order details and audit lifecycle history."""
    row = await supabase.get_one("orders", {"id": f"eq.{order_id}", "select": "*"})
    if not row:
        raise HTTPException(status_code=404, detail=f"Order '{order_id}' not found")

    dish_rows = await supabase.get("dishes", {"select": "*"})
    dish_map = {d["id"]: format_dish(d) for d in dish_rows}

    logs = await supabase.get(
        "order_status_logs",
        {"order_id": f"eq.{order_id}", "order": "timestamp.asc", "select": "*"},
    )
    return format_order(row, logs, dish_map)

@router.patch("/{order_id}/status")
async def update_order_status(order_id: str, payload: UpdateStatusPayload):
    """
    Update order status enforcing state machine and resolving race conditions.
    """
    try:
        updated_order = await supabase.rpc(
            "update_order_status_atomic",
            {
                "p_order_id": order_id,
                "p_new_status": payload.status,
                "p_note": payload.note or f"Status changed to {payload.status}",
            },
        )
    except Exception as e:
        error_msg = str(e)
        if "CANCEL_CONFLICT" in error_msg:
            raise HTTPException(
                status_code=409,
                detail="Conflict: Order has already started preparation by kitchen staff and can no longer be cancelled.",
            )
        if "INVALID_TRANSITION" in error_msg:
            raise HTTPException(status_code=400, detail=f"Invalid transition: {error_msg}")
        raise HTTPException(status_code=400, detail=f"Status update failed: {error_msg}")

    # Ensure fully formatted order structure for client synchronization
    try:
        full_order = await get_order_by_id(order_id)
    except Exception:
        full_order = updated_order

    # Broadcast ORDER_STATUS_CHANGED event in background
    ws_hub.broadcast_event_nowait(
        "ORDER_STATUS_CHANGED",
        {"orderId": order_id, "newStatus": payload.status, "order": full_order},
    )

    # If cancelled, inventory was restored, so broadcast inventory updates in background
    if payload.status == "cancelled":
        import asyncio
        async def _async_restore_inv():
            items = full_order.get("items") or []
            for item in items:
                dish_id = item.get("dishId")
                if dish_id:
                    try:
                        inv = await supabase.get_one("inventory", {"dish_id": f"eq.{dish_id}", "select": "*"})
                        if inv:
                            ws_hub.broadcast_event_nowait(
                                "INVENTORY_UPDATED",
                                {
                                    "dishId": dish_id,
                                    "availablePortions": inv.get("available_portions", 0),
                                    "isAvailable": inv.get("is_available", False),
                                },
                            )
                    except Exception:
                        pass
        asyncio.create_task(_async_restore_inv())

    return full_order

@router.post("/reset-data")
async def reset_all_orders():
    """Purge test orders and restore inventory stock (for clean testing)."""
    import asyncio
    # Run deletions concurrently
    await asyncio.gather(
        supabase.delete("order_status_logs", {"order_id": "neq.none"}),
        supabase.delete("idempotency_records", {"idempotency_key": "neq.none"}),
        supabase.delete("orders", {"id": "neq.none"}),
        return_exceptions=True,
    )

    default_stock = {"d1": 8, "d2": 12, "d3": 5, "d4": 15, "d5": 1}
    tasks = []
    for dish_id, stock in default_stock.items():
        tasks.append(supabase.patch("inventory", {"dish_id": f"eq.{dish_id}"}, {"available_portions": stock, "is_available": True}))
        tasks.append(supabase.patch("dishes", {"id": f"eq.{dish_id}"}, {"stock_count": stock, "is_available": True}))
    await asyncio.gather(*tasks, return_exceptions=True)

    ws_hub.broadcast_event_nowait("INVENTORY_UPDATED", {"dishId": "all", "reset": True})
    ws_hub.broadcast_event_nowait("ORDER_STATUS_CHANGED", {"orderId": "all", "reset": True})
    return {"status": "ok", "message": "All test orders cleared and inventory reset to default stock."}

@router.get("/{order_id}/receipt")
async def get_order_receipt(order_id: str):
    """Generate authoritative receipt matching ReceiptModel."""
    row = await supabase.get_one("orders", {"id": f"eq.{order_id}", "select": "*"})
    if not row:
        raise HTTPException(status_code=404, detail=f"Order '{order_id}' not found")

    subtotal = row.get("subtotal_cents", 0)
    tax = int(round(subtotal * 0.08))
    fee = row.get("fee_cents", 250)
    total = subtotal + tax + fee

    items = []
    for itm in row.get("items") or []:
        dish_info = itm.get("dish") or {}
        opt_names = itm.get("selectedOptionNames") or {}
        summary = ", ".join(opt_names.values()) if opt_names else ""
        items.append({
            "dishName": dish_info.get("name", "Gourmet Dish"),
            "customizationSummary": summary,
            "quantity": itm.get("quantity", 1),
            "unitPriceCents": itm.get("unitPriceCents", 0),
            "totalPriceCents": itm.get("totalPriceCents", 0),
        })

    return {
        "receiptNumber": f"RCP-{row.get('order_number')}",
        "orderId": row.get("id"),
        "orderNumber": str(row.get("order_number")),
        "issuedAt": row.get("updated_at") or row.get("created_at"),
        "customerName": row.get("customer_name"),
        "items": items,
        "subtotalCents": subtotal,
        "taxCents": tax,
        "serviceFeeCents": fee,
        "totalCents": total,
        "status": row.get("status", "pending"),
    }
