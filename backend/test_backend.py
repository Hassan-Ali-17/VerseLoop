import asyncio
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
import httpx
from backend.app.main import app

async def run_backend_verification():
    print("=" * 65)
    print("LOOPSERVE 3.0 — BACKEND VERIFICATION & CONCURRENCY TEST SUITE")
    print("=" * 65)

    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        # TEST 1: Health & Supabase Connectivity
        print("\n[TEST 1] Health Check & Database Connection...")
        h = await client.get("/api/v1/health")
        assert h.status_code == 200, f"Health check failed: {h.text}"
        print(f"  --> PASSED (200 OK): {h.json()['database']}")

        # TEST 2: Menu & Discovery
        print("\n[TEST 2] Menu & Discovery APIs...")
        dishes = await client.get("/api/v1/menu/dishes")
        assert dishes.status_code == 200 and len(dishes.json()) == 5
        print(f"  --> Loaded {len(dishes.json())} dishes from Supabase.")

        d1 = await client.get("/api/v1/menu/dishes/d1")
        assert d1.status_code == 200 and d1.json()["name"] == "Ember Signature Wagyu Burger"
        print(f"  --> Single dish lookup verified: {d1.json()['name']}")

        cats = await client.get("/api/v1/menu/categories")
        assert cats.status_code == 200 and "Main Course" in cats.json()
        print(f"  --> Categories verified: {cats.json()}")

        # TEST 3: Staff Inventory Management
        print("\n[TEST 3] Staff Inventory Query...")
        inv = await client.get("/api/v1/staff/inventory")
        assert inv.status_code == 200 and len(inv.json()) == 5
        print(f"  --> Staff inventory loaded: {len(inv.json())} tracked dishes.")

        # TEST 4: Idempotent Order Creation
        print("\n[TEST 4] Idempotent Order Creation & Deduplication...")
        idemp_key = f"test-idemp-{asyncio.get_event_loop().time()}"
        order_payload = {
            "idempotencyKey": idemp_key,
            "customerName": "Test Customer Alexander",
            "customerNotes": "Extra napkins please",
            "items": [
                {
                    "dishId": "d1",
                    "quantity": 1,
                    "unitPriceCents": 2450,
                    "totalPriceCents": 2450,
                    "dish": {"id": "d1", "name": "Ember Signature Wagyu Burger", "basePriceCents": 2450},
                    "selectedOptions": {"g_portion": "opt_p1"},
                    "selectedOptionNames": {"g_portion": "Classic Single"},
                }
            ],
        }

        # First Submission
        res1 = await client.post("/api/v1/orders", json=order_payload)
        assert res1.status_code == 200, f"Order 1 failed: {res1.text}"
        order1 = res1.json()
        order_id = order1["id"]
        print(f"  --> Initial Order Placed: ID {order_id}, Status: {order1['status']}")

        # Immediate Retry with exact same Idempotency Key
        res2 = await client.post("/api/v1/orders", json=order_payload)
        assert res2.status_code == 200
        order2 = res2.json()
        assert order1["id"] == order2["id"], "Idempotency failed: generated different order ID!"
        print(f"  --> Retry Succeeded with Same Idempotency Key: Replayed ID {order2['id']} without duplication!")

        # TEST 5: Order State Machine Transitions
        print("\n[TEST 5] Order State Machine Transition...")
        stat1 = await client.patch(f"/api/v1/orders/{order_id}/status", json={"status": "accepted", "note": "Kitchen acknowledged"})
        assert stat1.status_code == 200 and stat1.json()["status"] == "accepted"
        print(f"  --> Transitioned to ACCEPTED.")

        stat2 = await client.patch(f"/api/v1/orders/{order_id}/status", json={"status": "preparing", "note": "Chef started cooking"})
        assert stat2.status_code == 200 and stat2.json()["status"] == "preparing"
        print(f"  --> Transitioned to PREPARING.")

        # TEST 6: Concurrency Conflict Resolution (Cancellation vs Preparation)
        print("\n[TEST 6] Concurrency Conflict (Customer Cancel vs Staff Preparing)...")
        # Since order is in PREPARING, customer cancellation must trigger 409 Conflict
        cancel_clash = await client.patch(f"/api/v1/orders/{order_id}/status", json={"status": "cancelled"})
        assert cancel_clash.status_code == 409, f"Expected 409 Conflict, got {cancel_clash.status_code}"
        print("  --> PASSED: 409 Conflict correctly thrown because kitchen already began preparation!")

        # Complete Order
        stat3 = await client.patch(f"/api/v1/orders/{order_id}/status", json={"status": "ready"})
        assert stat3.status_code == 200
        stat4 = await client.patch(f"/api/v1/orders/{order_id}/status", json={"status": "handedOver"})
        assert stat4.status_code == 200 and stat4.json()["status"] == "handedOver"
        print(f"  --> Completed order lifecycle: HANDED_OVER.")

        # TEST 7: Authoritative Receipt Generation
        print("\n[TEST 7] Authoritative Receipt Generation...")
        rcp = await client.get(f"/api/v1/orders/{order_id}/receipt")
        assert rcp.status_code == 200
        print(f"  --> Receipt {rcp.json()['receiptNumber']} generated. Total: ${rcp.json()['totalCents']/100:.2f}")

        # TEST 8: Non-Negotiable Constraint: Two Customers Competing for Last Available Portion
        print("\n[TEST 8] NON-NEGOTIABLE CONSTRAINT: Two Customers Competing for Last Portion of Dish 'd5'...")
        # Ensure d5 has exactly 1 portion
        await client.patch("/api/v1/staff/inventory/d5/portions", json={"availablePortions": 1})

        cust_a_payload = {
            "idempotencyKey": f"race-a-{asyncio.get_event_loop().time()}",
            "customerName": "Customer Alice (Session 1)",
            "items": [{"dishId": "d5", "quantity": 1, "unitPriceCents": 1400}],
        }
        cust_b_payload = {
            "idempotencyKey": f"race-b-{asyncio.get_event_loop().time()}",
            "customerName": "Customer Bob (Session 2)",
            "items": [{"dishId": "d5", "quantity": 1, "unitPriceCents": 1400}],
        }

        # Fire both requests concurrently in parallel
        print("  --> Firing simultaneous requests for Alice and Bob...")
        results = await asyncio.gather(
            client.post("/api/v1/orders", json=cust_a_payload),
            client.post("/api/v1/orders", json=cust_b_payload),
            return_exceptions=True
        )

        statuses = [r.status_code for r in results if not isinstance(r, Exception)]
        print(f"  --> Responses received: {statuses}")

        # Exactly one must be 200 OK, and one must be 409 Conflict
        assert 200 in statuses, "At least one customer must succeed!"
        assert 409 in statuses, "Second customer must receive 409 Conflict (sold out)!"
        print("  --> PASSED: Exactly 1 customer succeeded (200) and 1 customer failed with 409 Conflict!")

        # Verify final database inventory is exactly 0 (not negative!)
        d5_inv = await client.get("/api/v1/staff/inventory")
        d5_record = next(item for item in d5_inv.json() if item["dishId"] == "d5")
        assert d5_record["availablePortions"] == 0, f"Expected 0 portions, got {d5_record['availablePortions']}"
        assert d5_record["isAvailable"] is False, "Expected dish to be marked sold out!"
        print(f"  --> Verified Inventory: Dish 'd5' availablePortions = {d5_record['availablePortions']}, isAvailable = {d5_record['isAvailable']} (NEVER NEGATIVE!)")

        print("\n" + "=" * 65)
        print("ALL 8 BACKEND REQUIREMENTS & CONCURRENCY TESTS PASSED PERFECTLY!")
        print("=" * 65)

if __name__ == "__main__":
    asyncio.run(run_backend_verification())
