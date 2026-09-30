from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.activities.router import router as activities_router
from app.admin.router import router as admin_router
from app.ai.router import router as ai_router
from app.analytics.router import router as analytics_router
from app.assessments.router import router as assessments_router
from app.auth.router import router as auth_router
from app.classrooms.router import router as classrooms_router
from app.core.config import settings
from app.core.exceptions import AppException
from app.db.init_db import init_db_schema, seed_initial_data
from app.db.session import AsyncSessionLocal
from app.feedback.router import router as feedback_router
from app.flashcards.router import router as santali_flashcards_router
from app.health.router import router as health_router
from app.language_packs.router import router as language_packs_router
from app.languages.router import router as languages_router
from app.lessons.router import router as lessons_router
from app.model_versions.router import router as model_versions_router
from app.nipun.router import router as nipun_router
from app.progress.router import router as progress_router
from app.resources.router import router as resources_router
from app.schools.router import router as schools_router
from app.sync.router import router as sync_router
from app.teachers.router import router as teachers_router
from app.verified_phrases.router import router as verified_phrases_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Ensure database schema is ready and seed base data
    await init_db_schema()
    async with AsyncSessionLocal() as session:
        await seed_initial_data(session)
    yield
    # Shutdown logic if needed


app = FastAPI(
    title="Maatribhasha Backend API",
    description=(
        "Modular monolith backend supporting the Maatribhasha offline-first Flutter application "
        "(SIH Problem Statement 26042). Manages curriculum, sync, language packs, "
        "assessments, teacher feedback, and server-side content preparation."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS middleware (Flutter Web development origins + origin regex)
cors_origins = [o for o in settings.BACKEND_CORS_ORIGINS if o != "*"]
if not cors_origins:
    cors_origins = [
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
    ]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Global Exception Handler
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "status": "error",
            "code": exc.code,
            "detail": exc.detail,
            "errors": exc.errors,
        },
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    # Prevent leaking stack traces in production
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "status": "error",
            "code": "INTERNAL_SERVER_ERROR",
            "detail": "An unexpected error occurred while processing your request.",
        },
    )


# Health Check (available at both /health and /api/v1/health)
app.include_router(health_router)
app.include_router(health_router, prefix=settings.API_V1_STR)

# Mount all API v1 routers
prefix = settings.API_V1_STR
app.include_router(auth_router, prefix=prefix)

# Alias /api/v1/me -> /api/v1/auth/me
from app.auth.router import get_current_user_profile
from app.auth.schemas import UserProfileResponse

app.add_api_route(
    f"{prefix}/me",
    get_current_user_profile,
    methods=["GET"],
    response_model=UserProfileResponse,
    tags=["Authentication"],
    summary="Get Current User Profile (Alias)",
)
app.include_router(schools_router, prefix=prefix)
app.include_router(teachers_router, prefix=prefix)
app.include_router(classrooms_router, prefix=prefix)
app.include_router(languages_router, prefix=prefix)
app.include_router(nipun_router, prefix=prefix)
app.include_router(lessons_router, prefix=prefix)
app.include_router(activities_router, prefix=prefix)
app.include_router(resources_router, prefix=prefix)
app.include_router(assessments_router, prefix=prefix)
app.include_router(progress_router, prefix=prefix)
app.include_router(language_packs_router, prefix=prefix)
app.include_router(model_versions_router, prefix=prefix)
app.include_router(sync_router, prefix=prefix)
app.include_router(feedback_router, prefix=prefix)
app.include_router(verified_phrases_router, prefix=prefix)
app.include_router(ai_router, prefix=prefix)
app.include_router(santali_flashcards_router, prefix=prefix)
app.include_router(analytics_router, prefix=prefix)
app.include_router(admin_router, prefix=prefix)


@app.get("/", tags=["Root"])
async def root():
    return {
        "service": "Maatribhasha Backend API",
        "status": "running",
        "docs": "/docs",
        "health": "/health",
        "api_v1": prefix,
    }
