from datetime import datetime, timezone
from typing import List, Dict, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from ..supabase_client import supabase
from ..websocket_hub import ws_hub

router = APIRouter(prefix="/staff", tags=["Staff & Inventory Operations"])

class UpdatePortionsPayload(BaseModel):
    availablePortions: int

class ToggleAvailabilityPayload(BaseModel):
    isAvailable: bool

def format_inventory(row: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "dishId": row.get("dish_id"),
        "dishName": row.get("dish_name"),
        "category": row.get("category"),
        "availablePortions": row.get("available_portions", 0),
        "isAvailable": row.get("is_available", True),
        "updatedAt": row.get("updated_at"),
    }

@router.get("/inventory")
async def get_inventory():
    """Retrieve current portion availability for all dishes."""
    rows = await supabase.get("inventory", {"select": "*", "order": "dish_id.asc"})
    return [format_inventory(r) for r in rows]

@router.patch("/inventory/{dish_id}/portions")
async def update_portions(dish_id: str, payload: UpdatePortionsPayload):
    """Update portion count for a dish and broadcast live update."""
    if payload.availablePortions < 0:
        raise HTTPException(status_code=400, detail="Portion count cannot be negative")

    now_iso = datetime.now(timezone.utc).isoformat()
    is_avail = payload.availablePortions > 0

    # 1. Update inventory table
    updated_inv = await supabase.patch(
        "inventory",
        {"dish_id": f"eq.{dish_id}"},
        {
            "available_portions": payload.availablePortions,
            "is_available": is_avail,
            "updated_at": now_iso,
        },
    )
    if not updated_inv:
        raise HTTPException(status_code=404, detail=f"Inventory for dish '{dish_id}' not found")

    # 2. Sync dishes table
    await supabase.patch(
        "dishes",
        {"id": f"eq.{dish_id}"},
        {
            "stock_count": payload.availablePortions,
            "is_available": is_avail,
            "updated_at": now_iso,
        },
    )

    inv_record = format_inventory(updated_inv[0])

    # 3. Broadcast real-time inventory update without blocking HTTP
    ws_hub.broadcast_event_nowait(
        "INVENTORY_UPDATED",
        {
            "dishId": dish_id,
            "availablePortions": payload.availablePortions,
            "isAvailable": is_avail,
        },
    )

    return inv_record

@router.patch("/inventory/{dish_id}/availability")
async def toggle_availability(dish_id: str, payload: ToggleAvailabilityPayload):
    """Toggle manual 86 / availability for a dish and broadcast update."""
    now_iso = datetime.now(timezone.utc).isoformat()

    updated_inv = await supabase.patch(
        "inventory",
        {"dish_id": f"eq.{dish_id}"},
        {
            "is_available": payload.isAvailable,
            "updated_at": now_iso,
        },
    )
    if not updated_inv:
        raise HTTPException(status_code=404, detail=f"Inventory for dish '{dish_id}' not found")

    await supabase.patch(
        "dishes",
        {"id": f"eq.{dish_id}"},
        {
            "is_available": payload.isAvailable,
            "updated_at": now_iso,
        },
    )

    inv_record = format_inventory(updated_inv[0])

    # Broadcast real-time update without blocking HTTP
    ws_hub.broadcast_event_nowait(
        "INVENTORY_UPDATED",
        {
            "dishId": dish_id,
            "availablePortions": inv_record["availablePortions"],
            "isAvailable": payload.isAvailable,
        },
    )

    return inv_record

