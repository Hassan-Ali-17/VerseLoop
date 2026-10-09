import json
import urllib.request

BASE = 'http://localhost:8080/api/v1'

def run():
    print("1. Purging test data...")
    req = urllib.request.Request(f'{BASE}/orders/reset-data', data=b'{}', headers={'Content-Type': 'application/json'}, method='POST')
    res = urllib.request.urlopen(req)
    print("Reset response:", res.read().decode())

    print("2. Placing new order...")
    order_payload = {
        'idempotencyKey': 'test-e2e-handover-test',
        'customerName': 'Test Customer Alexander',
        'items': [{'dishId': 'd1', 'quantity': 1}]
    }
    req = urllib.request.Request(f'{BASE}/orders', data=json.dumps(order_payload).encode(), headers={'Content-Type': 'application/json'}, method='POST')
    order = json.loads(urllib.request.urlopen(req).read().decode())
    order_id = order['id']
    print(f"Placed order: {order_id}, initial status: {order['status']}")

    for next_st in ['accepted', 'preparing', 'ready', 'handedOver']:
        p = json.dumps({'status': next_st}).encode()
        r = urllib.request.Request(f'{BASE}/orders/{order_id}/status', data=p, headers={'Content-Type': 'application/json'}, method='PATCH')
        updated = json.loads(urllib.request.urlopen(r).read().decode())
        print(f"Updated order to: {updated['status']}")

    print("3. Verifying GET /orders/{order_id}...")
    req = urllib.request.Request(f'{BASE}/orders/{order_id}')
    fetched = json.loads(urllib.request.urlopen(req).read().decode())
    print(f"Fetched status: {fetched['status']}")
    assert fetched['status'] == 'handedOver', f"Expected handedOver but got {fetched['status']}"

    print("4. Verifying GET /orders/completed...")
    req = urllib.request.Request(f'{BASE}/orders/completed')
    completed = json.loads(urllib.request.urlopen(req).read().decode())
    found = any(o['id'] == order_id for o in completed)
    print(f"Order found in completed orders: {found}")
    assert found, "Order must be in completed orders!"

    print("5. Purging test data after verification so user starts clean...")
    req = urllib.request.Request(f'{BASE}/orders/reset-data', data=b'{}', headers={'Content-Type': 'application/json'}, method='POST')
    urllib.request.urlopen(req)
    print("ALL VERIFICATIONS PASSED! System is 100% clean and ready for user testing.")

if __name__ == '__main__':
    run()
