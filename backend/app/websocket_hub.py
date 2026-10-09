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
            self.active_connections.remove(websocket)

    async def broadcast_event(self, event_name: str, data: Dict[str, Any]):
        self._event_version += 1
        payload = {
            "event": event_name,
            "data": data,
            "eventId": f"evt-{uuid.uuid4().hex[:12]}",
            "version": self._event_version,
        }
        message_str = json.dumps(payload)

        # Broadcast to all live clients
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_text(message_str)
            except Exception:
                disconnected.append(connection)

        for conn in disconnected:
            self.disconnect(conn)

ws_hub = WebSocketHub()
