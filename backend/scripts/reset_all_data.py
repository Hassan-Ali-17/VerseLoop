import asyncio
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from backend.app.supabase_client import supabase
from backend.app.websocket_hub import ws_hub

async def reset_data():
    print("Purging database test records...")
    
    # 1. Delete order status logs
    try:
        await supabase.delete("order_status_logs", {"order_id": "neq.none"})
        print("Cleared order_status_logs.")
    except Exception as e:
        print(f"order_status_logs delete: {e}")

    # 2. Delete idempotency records
    try:
        await supabase.delete("idempotency_records", {"idempotency_key": "neq.none"})
        print("Cleared idempotency_records.")
    except Exception as e:
        print(f"idempotency_records delete: {e}")

    # 3. Delete orders
    try:
        await supabase.delete("orders", {"id": "neq.none"})
        print("Cleared orders.")
    except Exception as e:
        print(f"orders delete: {e}")

    # 4. Reset inventory and dishes
    default_stock = {
        "d1": 8,
        "d2": 12,
        "d3": 5,
        "d4": 15,
        "d5": 1,
    }

    for dish_id, stock in default_stock.items():
        try:
            await supabase.patch(
                "inventory",
                {"dish_id": f"eq.{dish_id}"},
                {"available_portions": stock, "is_available": True}
            )
            await supabase.patch(
                "dishes",
                {"id": f"eq.{dish_id}"},
                {"stock_count": stock, "is_available": True}
            )
            print(f"Reset {dish_id} to {stock} portions.")
        except Exception as e:
            print(f"Failed to reset {dish_id}: {e}")

    print("Data reset complete! Database is clean and ready.")

if __name__ == "__main__":
    asyncio.run(reset_data())
