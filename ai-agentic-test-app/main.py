# Sample Python FastAPI application for testing Tilt environment
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="AI Agentic Test App", version="1.0.0")

@app.get("/")
async def root():
    return {"message": "AI Agentic Test App is running!", "environment": os.getenv("ENVIRONMENT", "unknown")}

@app.get("/health")
async def health_check():
    return JSONResponse(
        status_code=200,
        content={
            "status": "healthy",
            "service": "ai-agentic-test-app",
            "environment": os.getenv("ENVIRONMENT", "unknown"),
            "log_level": os.getenv("LOG_LEVEL", "INFO")
        }
    )

@app.get("/config")
async def get_config():
    return {
        "database_url": os.getenv("DATABASE_URL", "not configured"),
        "redis_url": os.getenv("REDIS_URL", "not configured"),
        "environment": os.getenv("ENVIRONMENT", "unknown"),
        "port": os.getenv("PORT", "8000")
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
