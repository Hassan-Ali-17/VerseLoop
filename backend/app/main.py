import json
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from .config import settings
from .supabase_client import supabase
from .websocket_hub import ws_hub
from .routers import menu, orders, staff

app = FastAPI(
    title="LoopServe 3.0 Backend",
    description="Advanced Restaurant Operations API & Realtime Server",
    version="1.0.0",
)

# Enable CORS for Flutter web / desktop / local dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(menu.router, prefix=settings.API_PREFIX)
app.include_router(orders.router, prefix=settings.API_PREFIX)
app.include_router(staff.router, prefix=settings.API_PREFIX)

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """Realtime WebSocket endpoint for order and inventory live synchronization."""
    await ws_hub.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            try:
                msg = json.loads(data)
                if msg.get("type") == "PING":
                    await websocket.send_text(json.dumps({"type": "PONG"}))
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_hub.disconnect(websocket)
    except Exception:
        ws_hub.disconnect(websocket)



@app.get(f"{settings.API_PREFIX}/health")
async def health_check():
    """Verify server status and Supabase database connectivity."""
    try:
        # Check database connectivity
        dishes = await supabase.get("dishes", {"select": "id", "limit": "1"})
        return {
            "status": "healthy",
            "server": "LoopServe FastAPI Backend",
            "database": "Supabase Connected",
            "sample_dish_found": bool(dishes),
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Database unreachable: {str(e)}")

@app.get("/")
async def root():
    return {
        "name": "LoopServe 3.0 API",
        "docs": "/docs",
        "health": f"{settings.API_PREFIX}/health",
    }
