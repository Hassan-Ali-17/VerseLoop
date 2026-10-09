import asyncio
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from backend.app.supabase_client import supabase
from backend.app.routers.menu import format_dish

async def fix():
    dishes = await supabase.get("dishes", {"select": "*"})
    dish_map = {d["id"]: format_dish(d) for d in dishes}
    orders = await supabase.get("orders", {"select": "*"})
    print(f"Sanitizing {len(orders)} orders...")
    for o in orders:
        updated_items = []
        for it in o.get("items", []):
            d_id = it.get("dishId") or (it.get("dish") or {}).get("id")
            if d_id and d_id in dish_map:
                it["dishId"] = d_id
                it["dish"] = dish_map[d_id]
                it.setdefault("id", f"item-{d_id}")
                it.setdefault("selectedOptions", {})
                it.setdefault("selectedOptionNames", {})
                it.setdefault("extraPriceCents", 0)
                it.setdefault("quantity", 1)
                it.setdefault("unitPriceCents", dish_map[d_id]["basePriceCents"])
                it.setdefault("totalPriceCents", it["unitPriceCents"] * it["quantity"])
            updated_items.append(it)
        await supabase.patch("orders", {"id": f"eq.{o['id']}"}, {"items": updated_items})
    print("All orders successfully sanitized with full Dish metadata!")

if __name__ == "__main__":
    asyncio.run(fix())
