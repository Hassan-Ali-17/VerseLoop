import asyncio
import json
import uuid
from typing import List, Dict, Any
from fastapi import WebSocket

class WebSocketHub:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self._event_version = 0

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            try:
                self.active_connections.remove(websocket)
            except ValueError:
                pass

    def broadcast_event_nowait(self, event_name: str, data: Dict[str, Any]):
        """Schedule broadcast in background without blocking the HTTP handler."""
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(self.broadcast_event(event_name, data))
        except Exception:
            pass

    async def broadcast_event(self, event_name: str, data: Dict[str, Any]):
        self._event_version += 1
        payload = {
            "event": event_name,
            "data": data,
            "eventId": f"evt-{uuid.uuid4().hex[:12]}",
            "version": self._event_version,
        }
        message_str = json.dumps(payload)

        if not self.active_connections:
            return

        conns = list(self.active_connections)
        disconnected = []

        async def _safe_send(ws: WebSocket):
            try:
                # 300ms strict timeout: dead sockets NEVER stall the HTTP response
                await asyncio.wait_for(ws.send_text(message_str), timeout=0.3)
                return True
            except Exception:
                disconnected.append(ws)
                return False

        # Broadcast concurrently across all active connections
        await asyncio.gather(*[_safe_send(ws) for ws in conns], return_exceptions=True)

        for dead in disconnected:
            self.disconnect(dead)

ws_hub = WebSocketHub()
