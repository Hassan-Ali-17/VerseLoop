from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional, Dict, Any
import asyncio
from ..supabase_client import supabase

router = APIRouter(prefix="/menu", tags=["Menu & Discovery"])

def format_dish(row: Dict[str, Any], inv: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Format database row to camelCase JSON matching Flutter Dish model."""
    stock = inv.get("available_portions") if (inv and "available_portions" in inv) else row.get("stock_count", 0)
    avail = (inv.get("is_available", True) and stock > 0) if inv else (row.get("is_available", True) and stock > 0)
    return {
        "id": row.get("id"),
        "name": row.get("name"),
        "category": row.get("category"),
        "description": row.get("description"),
        "basePriceCents": row.get("base_price_cents"),
        "imageUrl": row.get("image_url"),
        "model3dId": row.get("model_3d_id"),
        "isAvailable": avail,
        "stockCount": stock,
        "isFeatured": row.get("is_featured", False),
        "ingredients": row.get("ingredients") or [],
        "customizationGroups": row.get("customization_groups") or [],
    }

@router.get("/dishes")
async def get_all_dishes():
    """Retrieve all restaurant dishes with synchronized inventory."""
    dishes, inv_rows = await asyncio.gather(
        supabase.get("dishes", {"select": "*", "order": "id.asc"}),
        supabase.get("inventory", {"select": "*"}),
        return_exceptions=True,
    )
    if isinstance(dishes, Exception):
        raise HTTPException(status_code=500, detail=str(dishes))
    inv_map = {i["dish_id"]: i for i in (inv_rows if isinstance(inv_rows, list) else [])}
    return [format_dish(r, inv_map.get(r["id"])) for r in dishes]

@router.get("/dishes/{dish_id}")
async def get_dish_by_id(dish_id: str):
    """Retrieve single dish by unique ID with synchronized inventory."""
    row = await supabase.get_one("dishes", {"id": f"eq.{dish_id}", "select": "*"})
    if not row:
        raise HTTPException(status_code=404, detail=f"Dish '{dish_id}' not found")
    inv = await supabase.get_one("inventory", {"dish_id": f"eq.{dish_id}", "select": "*"})
    return format_dish(row, inv)

@router.get("/categories")
async def get_categories() -> List[str]:
    """Retrieve list of distinct menu categories."""
    rows = await supabase.get("dishes", {"select": "category"})
    cats = ["All"]
    seen = set()
    for r in rows:
        c = r.get("category")
        if c and c not in seen:
            seen.add(c)
            cats.append(c)
    return cats

@router.get("/search")
async def search_dishes(
    q: Optional[str] = Query(None, description="Search query"),
    category: Optional[str] = Query(None, description="Filter category"),
):
    """Search and filter dishes by name, description, ingredients, or category with live inventory."""
    dishes, inv_rows = await asyncio.gather(
        supabase.get("dishes", {"select": "*", "order": "id.asc"}),
        supabase.get("inventory", {"select": "*"}),
        return_exceptions=True,
    )
    if isinstance(dishes, Exception):
        raise HTTPException(status_code=500, detail=str(dishes))
    inv_map = {i["dish_id"]: i for i in (inv_rows if isinstance(inv_rows, list) else [])}

    results = []
    q_lower = (q or "").strip().lower()
    cat_filter = category if category and category != "All" else None

    for r in dishes:
        if cat_filter and r.get("category") != cat_filter:
            continue

        if q_lower:
            name = (r.get("name") or "").lower()
            desc = (r.get("description") or "").lower()
            ingredients = " ".join(r.get("ingredients") or []).lower()
            if q_lower not in name and q_lower not in desc and q_lower not in ingredients:
                continue

        results.append(format_dish(r, inv_map.get(r["id"])))

    return results
