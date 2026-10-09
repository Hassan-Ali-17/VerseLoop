import httpx
from typing import Any, Dict, List, Optional
from .config import settings

class SupabaseClient:
    def __init__(self):
        self.base_url = f"{settings.SUPABASE_URL.rstrip('/')}/rest/v1"
        self.headers = {
            "apikey": settings.SUPABASE_SERVICE_ROLE_KEY,
            "Authorization": f"Bearer {settings.SUPABASE_SERVICE_ROLE_KEY}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    async def get(self, table: str, params: Optional[Dict[str, str]] = None) -> List[Dict[str, Any]]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(f"{self.base_url}/{table}", headers=self.headers, params=params)
            resp.raise_for_status()
            return resp.json()

    async def get_one(self, table: str, params: Optional[Dict[str, str]] = None) -> Optional[Dict[str, Any]]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(f"{self.base_url}/{table}", headers=self.headers, params=params)
            resp.raise_for_status()
            data = resp.json()
            return data[0] if data else None

    async def post(self, table: str, data: Dict[str, Any]) -> List[Dict[str, Any]]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(f"{self.base_url}/{table}", headers=self.headers, json=data)
            resp.raise_for_status()
            return resp.json()

    async def patch(self, table: str, params: Dict[str, str], data: Dict[str, Any]) -> List[Dict[str, Any]]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.patch(f"{self.base_url}/{table}", headers=self.headers, params=params, json=data)
            resp.raise_for_status()
            return resp.json()

    async def delete(self, table: str, params: Dict[str, str]) -> List[Dict[str, Any]]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.delete(f"{self.base_url}/{table}", headers=self.headers, params=params)
            resp.raise_for_status()
            return resp.json()

    async def rpc(self, function_name: str, params: Dict[str, Any]) -> Any:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(f"{self.base_url}/rpc/{function_name}", headers=self.headers, json=params)
            if resp.status_code >= 400:
                error_detail = resp.text
                try:
                    error_json = resp.json()
                    error_detail = error_json.get("message", error_detail)
                except Exception:
                    pass
                raise Exception(f"RPC Error ({resp.status_code}): {error_detail}")
            return resp.json()

supabase = SupabaseClient()
