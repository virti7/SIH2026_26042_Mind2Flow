import os
from typing import List, Optional
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Maatribhasha Backend"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    PORT: int = 8000
    HOST: str = "0.0.0.0"

    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./maatribhasha.db"
    DATABASE_URL_LOCAL: Optional[str] = None
    DATABASE_URL_POSTGRES: Optional[str] = None

    # Supabase Auth & Keys
    SUPABASE_URL: Optional[str] = "https://example.supabase.co"
    SUPABASE_ANON_KEY: Optional[str] = "dummy-anon-key"
    SUPABASE_SERVICE_ROLE_KEY: Optional[str] = "dummy-service-role-key"
    SUPABASE_PUBLISHABLE_KEY: Optional[str] = None
    SUPABASE_SECRET_KEY: Optional[str] = None

    # Supabase JWT & JWKS
    SUPABASE_JWT_SECRET: Optional[str] = "super-secret-dev-jwt-key-for-local-testing-only-1234567890"
    SUPABASE_JWT_ALGORITHM: str = "HS256"
    SUPABASE_JWT_ISSUER: Optional[str] = None
    SUPABASE_JWKS_URL: Optional[str] = None
    SUPABASE_JWT_AUDIENCE: Optional[str] = "authenticated"
    SUPABASE_JWKS_CACHE_TTL_SECONDS: int = 600

    # Storage Buckets
    STORAGE_BUCKET_LANGUAGE_PACKS: str = "language-packs"
    STORAGE_BUCKET_MODELS: str = "models"
    STORAGE_BUCKET_CONTENT: str = "content"
    # Category buckets for generated resources. Defaults mirror STORAGE_BUCKET_CONTENT
    # unless the Supabase project defines dedicated buckets; confirm bucket names
    # in the Supabase dashboard and override via environment.
    STORAGE_BUCKET_GENERATED_RESOURCES: Optional[str] = None
    STORAGE_BUCKET_WORKSHEETS: Optional[str] = None
    STORAGE_BUCKET_FLASHCARDS: Optional[str] = None

    # CORS
    # Default ["*"] works for Flutter Web local development because the app
    # issues non-credentialed requests (no cookies; `flutter run -d chrome`
    # serves from http://localhost:<random-port>). Override via env JSON list,
    # e.g. BACKEND_CORS_ORIGINS='["https://your-frontend-host"]'.
    # NOTE: browsers reject "*" for credentialed requests, so production
    # deployments that use credentialed auth MUST set explicit origins.
    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    # --- Local model service (app/, this repository) --------------------------
    # All AI inference is local. The backend forwards text translation to the
    # project's own ONNX/IndicTrans2 service over loopback. There is no
    # third-party AI provider, no API key, and no outbound AI request.
    LOCAL_TRANSLATION_SERVICE_URL: str = "http://127.0.0.1:7871"
    LOCAL_TRANSLATION_SERVICE_TIMEOUT: float = 120.0

    # Server-side content generation is unavailable in this build: no cloud
    # model is configured. Generation endpoints return a clear 503 rather than
    # returning fabricated or pre-baked content.
    CONTENT_GENERATION_ENABLED: bool = False
    CONTENT_GENERATION_UNAVAILABLE_REASON: str = (
        "This build runs entirely offline and has no content-generation model. "
        "Upload or author worksheet content instead of generating it."
    )

    # Custom NMT endpoints for languages no local model covers (resolved from
    # the ModelVersion registry when unset; plain HTTP translation endpoints).
    HO_NMT_ENDPOINT: Optional[str] = None
    MUNDARI_NMT_ENDPOINT: Optional[str] = None
    # Optional JSON glossaries: {"source text": "translated text"} per language.
    HO_GLOSSARY_PATH: Optional[str] = None
    MUNDARI_GLOSSARY_PATH: Optional[str] = None
    # Optional approved local-context library JSON for contextual worksheets.
    WORKSHEET_LOCAL_CONTEXT_PATH: Optional[str] = None
    # Santali flashcard picture library (metadata/assets.json +
    # config/taxonomy.json). Defaults to the Flutter-bundled dataset at
    # <repo>/assets/prototype_content/flashcards when unset.
    FLASHCARD_IMAGE_LIBRARY_DIR: Optional[str] = None
    BILINGUAL_GENERATOR_DIR: Optional[str] = "generator"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    def model_post_init(self, __context):
        import re

        # 1. Resolve PostgreSQL URL if given
        if self.DATABASE_URL_POSTGRES:
            raw_url = self.DATABASE_URL_POSTGRES
            # Strip placeholder brackets if user left them: :[password]@ -> :password@
            clean_url = re.sub(r":\[(.*?)\]@", r":\1@", raw_url)
            if clean_url.startswith("postgresql://"):
                clean_url = clean_url.replace("postgresql://", "postgresql+asyncpg://", 1)
            elif clean_url.startswith("postgres://"):
                clean_url = clean_url.replace("postgres://", "postgresql+asyncpg://", 1)
            # If DATABASE_URL was not explicitly set or is default sqlite, use postgres
            if not os.getenv("DATABASE_URL") or self.DATABASE_URL == "sqlite+aiosqlite:///./maatribhasha.db":
                self.DATABASE_URL = clean_url
        elif self.DATABASE_URL:
            self.DATABASE_URL = re.sub(r":\[(.*?)\]@", r":\1@", self.DATABASE_URL)
            if self.DATABASE_URL.startswith("postgresql://"):
                self.DATABASE_URL = self.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)
            elif self.DATABASE_URL.startswith("postgres://"):
                self.DATABASE_URL = self.DATABASE_URL.replace("postgres://", "postgresql+asyncpg://", 1)

        # 2. Map Publishable & Secret keys
        if self.SUPABASE_PUBLISHABLE_KEY and (not self.SUPABASE_ANON_KEY or self.SUPABASE_ANON_KEY == "dummy-anon-key"):
            self.SUPABASE_ANON_KEY = self.SUPABASE_PUBLISHABLE_KEY
        if self.SUPABASE_SECRET_KEY and (not self.SUPABASE_SERVICE_ROLE_KEY or self.SUPABASE_SERVICE_ROLE_KEY == "dummy-service-role-key"):
            self.SUPABASE_SERVICE_ROLE_KEY = self.SUPABASE_SECRET_KEY


settings = Settings()
