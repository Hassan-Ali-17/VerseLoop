import time
import urllib.request
import json

BASE = 'http://localhost:8080/api/v1'

def test_endpoint(name, method, url, data=None):
    t0 = time.time()
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode() if data else None,
        headers={'Content-Type': 'application/json'},
        method=method
    )
    try:
        res = urllib.request.urlopen(req, timeout=15)
        dt = time.time() - t0
        print(f"{name}: {res.status} in {dt:.3f}s")
        return json.loads(res.read().decode())
    except Exception as e:
        dt = time.time() - t0
        print(f"{name} FAILED in {dt:.3f}s: {e}")
        return None

def main():
    test_endpoint('RESET', 'POST', f'{BASE}/orders/reset-data', {})
    test_endpoint('GET active', 'GET', f'{BASE}/orders/active')
    ord_res = test_endpoint('CREATE order', 'POST', f'{BASE}/orders', {
        'idempotencyKey': f'perf-test-{time.time()}',
        'customerName': 'Speed Test',
        'items': [{'dishId': 'd1', 'quantity': 1}]
    })
    if ord_res:
        oid = ord_res['id']
        test_endpoint('PATCH accepted', 'PATCH', f'{BASE}/orders/{oid}/status', {'status': 'accepted'})
        test_endpoint('PATCH preparing', 'PATCH', f'{BASE}/orders/{oid}/status', {'status': 'preparing'})
        test_endpoint('PATCH ready', 'PATCH', f'{BASE}/orders/{oid}/status', {'status': 'ready'})
        test_endpoint('PATCH handedOver', 'PATCH', f'{BASE}/orders/{oid}/status', {'status': 'handedOver'})

    test_endpoint('PATCH portions', 'PATCH', f'{BASE}/staff/inventory/d1/portions', {'availablePortions': 7})
    test_endpoint('PATCH availability', 'PATCH', f'{BASE}/staff/inventory/d1/availability', {'isAvailable': True})
    test_endpoint('CLEANUP RESET', 'POST', f'{BASE}/orders/reset-data', {})

if __name__ == '__main__':
    main()
