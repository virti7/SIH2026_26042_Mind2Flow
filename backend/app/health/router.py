from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_db

router = APIRouter(tags=["Health"])


@router.get("/health", summary="Service Health Check")
async def health_check(db: AsyncSession = Depends(get_db)):
    """
    Performs a health check verifying server uptime and database connectivity
    without exposing any sensitive credentials or secrets.
    """
    db_status = "healthy"
    try:
        await db.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    # Verify critical application queries still work against the real
    # schema (e.g. teachers.username must exist for auth/profile flows).
    # A SELECT 1 alone would hide such mismatches.
    if db_status == "healthy":
        try:
            await db.execute(text("SELECT id, username FROM teachers LIMIT 1"))
        except Exception as e:
            db_status = f"unhealthy: teachers table probe failed: {str(e)}"

    return {
        "status": "ok" if db_status == "healthy" else "degraded",
        "service": settings.PROJECT_NAME,
        "environment": settings.ENVIRONMENT,
        "database": db_status,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
