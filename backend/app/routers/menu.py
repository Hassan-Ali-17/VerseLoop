from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional, Dict, Any
from ..supabase_client import supabase

router = APIRouter(prefix="/menu", tags=["Menu & Discovery"])

def format_dish(row: Dict[str, Any]) -> Dict[str, Any]:
    """Format database row to camelCase JSON matching Flutter Dish model."""
    return {
        "id": row.get("id"),
        "name": row.get("name"),
        "category": row.get("category"),
        "description": row.get("description"),
        "basePriceCents": row.get("base_price_cents"),
        "imageUrl": row.get("image_url"),
        "model3dId": row.get("model_3d_id"),
        "isAvailable": row.get("is_available", True),
        "stockCount": row.get("stock_count", 0),
        "isFeatured": row.get("is_featured", False),
        "ingredients": row.get("ingredients") or [],
        "customizationGroups": row.get("customization_groups") or [],
    }

@router.get("/dishes")
async def get_all_dishes():
    """Retrieve all restaurant dishes."""
    rows = await supabase.get("dishes", {"select": "*", "order": "id.asc"})
    return [format_dish(r) for r in rows]

@router.get("/dishes/{dish_id}")
async def get_dish_by_id(dish_id: str):
    """Retrieve single dish by unique ID."""
    row = await supabase.get_one("dishes", {"id": f"eq.{dish_id}", "select": "*"})
    if not row:
        raise HTTPException(status_code=404, detail=f"Dish '{dish_id}' not found")
    return format_dish(row)

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
    """Search and filter dishes by name, description, ingredients, or category."""
    rows = await supabase.get("dishes", {"select": "*", "order": "id.asc"})
    results = []

    q_lower = (q or "").strip().lower()
    cat_filter = category if category and category != "All" else None

    for r in rows:
        if cat_filter and r.get("category") != cat_filter:
            continue

        if q_lower:
            name = (r.get("name") or "").lower()
            desc = (r.get("description") or "").lower()
            ingredients = " ".join(r.get("ingredients") or []).lower()
            if q_lower not in name and q_lower not in desc and q_lower not in ingredients:
                continue

        results.append(format_dish(r))

    return results
