import uvicorn
from backend.app.config import settings

if __name__ == "__main__":
    print(f"Starting LoopServe 3.0 Backend Server on http://localhost:{settings.PORT} ...")
    uvicorn.run("backend.app.main:app", host=settings.HOST, port=settings.PORT, reload=True, reload_dirs=["backend/app"])
