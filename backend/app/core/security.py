import json
import time
import urllib.request
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from jose import JWTError, jwt
from pydantic import BaseModel

from app.core.config import settings
from app.core.exceptions import UnauthorizedException

# In-memory JWKS cache: {"keys": [...], "fetched_at": epoch_seconds}
_jwks_cache: Dict[str, Any] = {"keys": None, "fetched_at": 0.0}

# Known non-secret dev placeholders that must never be accepted in production.
_DEV_SECRET_MARKERS = (
    "dev-secret",
    "dummy",
    "example",
    "super-secret-dev-jwt-key",
    "super-secret-jwt-key",
    "test",
    "changeme",
)

_ES_JWKS_ALGORITHMS = ("ES256",)
_RSA_JWKS_ALGORITHMS = ("RS256",)


class UserContext(BaseModel):
    user_id: str
    email: Optional[str] = None
    role: str = "teacher"  # teacher, admin, content_reviewer, language_expert
    school_id: Optional[str] = None
    language_preferences: List[str] = []
    app_metadata: Dict[str, Any] = {}
    user_metadata: Dict[str, Any] = {}

    def is_admin(self) -> bool:
        return self.role.lower() == "admin"

    def is_reviewer(self) -> bool:
        return self.role.lower() in ("admin", "content_reviewer", "language_expert")


def _is_production() -> bool:
    return (settings.ENVIRONMENT or "").strip().lower() == "production"


def _is_placeholder_url(url: Optional[str]) -> bool:
    if not url:
        return True
    lowered = url.lower()
    return "example" in lowered or "your-project" in lowered or "dummy" in lowered


def _is_dev_secret(value: Optional[str]) -> bool:
    if not value:
        return True
    lowered = value.lower()
    return any(marker in lowered for marker in _DEV_SECRET_MARKERS)


def get_jwks_url(issuer: Optional[str] = None) -> Optional[str]:
    """Return the configured JWKS URL, deriving it from SUPABASE_URL when unset or token issuer."""
    if settings.SUPABASE_JWKS_URL:
        return settings.SUPABASE_JWKS_URL
    base = (settings.SUPABASE_URL or "").rstrip("/")
    if base and not _is_placeholder_url(base):
        return f"{base}/auth/v1/.well-known/jwks.json"
    if issuer and issuer.startswith("https://") and ".supabase.co" in issuer:
        clean = issuer.rstrip("/")
        if not clean.endswith("/auth/v1"):
            clean = f"{clean}/auth/v1"
        return f"{clean}/.well-known/jwks.json"
    return None


def get_expected_issuer(issuer: Optional[str] = None) -> Optional[str]:
    """Return the expected JWT issuer, deriving it from SUPABASE_URL when unset or token issuer."""
    if settings.SUPABASE_JWT_ISSUER:
        return settings.SUPABASE_JWT_ISSUER
    base = (settings.SUPABASE_URL or "").rstrip("/")
    if base and not _is_placeholder_url(base):
        return f"{base}/auth/v1"
    if issuer and issuer.startswith("https://") and ".supabase.co" in issuer:
        clean = issuer.rstrip("/")
        if not clean.endswith("/auth/v1"):
            clean = f"{clean}/auth/v1"
        return clean
    return None


def _fetch_jwks(force_refresh: bool = False, issuer: Optional[str] = None) -> List[Dict[str, Any]]:
    """Fetch and cache the JWKS key set. Raises UnauthorizedException on failure."""
    jwks_url = get_jwks_url(issuer)
    if not jwks_url:
        raise UnauthorizedException(
            "Token verification unavailable: SUPABASE_JWKS_URL is not configured"
        )

    ttl = settings.SUPABASE_JWKS_CACHE_TTL_SECONDS or 600
    now = time.time()
    cached_keys = _jwks_cache.get("keys")
    fetched_at = float(_jwks_cache.get("fetched_at") or 0.0)
    if not force_refresh and cached_keys and (now - fetched_at) < ttl:
        return cached_keys  # type: ignore[return-value]

    try:
        req = urllib.request.Request(jwks_url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=8) as resp:  # noqa: S310
            raw = resp.read().decode("utf-8")
        data = json.loads(raw)
    except Exception as exc:
        # Fail securely: never accept a token when the key set cannot be loaded.
        # Serve stale cache if we have one rather than failing open.
        if cached_keys:
            return cached_keys  # type: ignore[return-value]
        raise UnauthorizedException(
            "Token verification unavailable: unable to fetch JWKS"
        ) from exc

    keys = data.get("keys") if isinstance(data, dict) else None
    if not keys:
        raise UnauthorizedException("Token verification unavailable: JWKS has no keys")
    _jwks_cache["keys"] = keys
    _jwks_cache["fetched_at"] = now
    return keys


def _find_jwk(keys: List[Dict[str, Any]], kid: Optional[str]) -> Dict[str, Any]:
    if kid:
        for key in keys:
            if key.get("kid") == kid:
                return key
        # SECURITY: the JWT explicitly names a signing key that is not in the
        # JWKS. Reject here and never fall back to a different key — verifying
        # against a key the issuer did not select would bypass key selection.
        raise UnauthorizedException("Invalid token: signing key (kid) not found in JWKS")
    # No kid in the JWT: allow only an unambiguous single-key set.
    if len(keys) == 1:
        return keys[0]
    raise UnauthorizedException("Invalid token: signing key (kid) not found in JWKS")


PRIVILEGED_ROLES = {"admin", "teacher", "content_reviewer", "language_expert"}


def _payload_to_user_context(payload: Dict[str, Any], db_role: Optional[str] = None) -> UserContext:
    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedException("Invalid token payload: missing sub (user ID)")

    email = payload.get("email")
    app_metadata = payload.get("app_metadata", {}) or {}
    user_metadata = payload.get("user_metadata", {}) or {}

    # Authoritative role resolution:
    # 1. Explicit server-side database lookup role (if resolved)
    # 2. Supabase app_metadata["role"] (authoritative server-controlled claim in Supabase)
    # 3. For test/dev tokens only (non-production): payload.get("role")
    #
    # SECURITY: We NEVER trust user_metadata["role"], request body, or client headers
    # for privileged roles (teacher, admin, content_reviewer, language_expert).
    role: str = "authenticated"
    if db_role and db_role.strip():
        role = db_role.strip().lower()
    elif app_metadata.get("role"):
        role = str(app_metadata["role"]).strip().lower()
    elif not _is_production() and payload.get("role"):
        # Permitted only in dev/test for test convenience
        role = str(payload["role"]).strip().lower()
    else:
        # Check user_metadata ONLY for non-privileged roles (e.g., student)
        untrusted_role = str(user_metadata.get("role", "")).strip().lower()
        if untrusted_role and untrusted_role not in PRIVILEGED_ROLES:
            role = untrusted_role
        else:
            role = "student"

    school_id = user_metadata.get("school_id") or app_metadata.get("school_id")
    language_preferences = (
        payload.get("language_preferences")
        or user_metadata.get("language_preferences")
        or []
    )

    return UserContext(
        user_id=str(user_id),
        email=email,
        role=role.lower(),
        school_id=str(school_id) if school_id else None,
        language_preferences=list(language_preferences) if isinstance(language_preferences, (list, tuple)) else [],
        app_metadata=app_metadata,
        user_metadata=user_metadata,
    )



def _verify_with_jwks(token: str, kid: Optional[str], algorithms: List[str]) -> Dict[str, Any]:
    token_issuer: Optional[str] = None
    try:
        unverified_claims = jwt.get_unverified_claims(token)
        token_issuer = unverified_claims.get("iss")
    except Exception:
        pass

    try:
        keys = _fetch_jwks(issuer=token_issuer)
    except TypeError:
        keys = _fetch_jwks()
    jwk = _find_jwk(keys, kid)

    decode_kwargs: Dict[str, Any] = {"algorithms": algorithms}
    issuer = get_expected_issuer(token_issuer)
    if issuer:
        decode_kwargs["issuer"] = issuer
    audience = settings.SUPABASE_JWT_AUDIENCE
    if audience:
        decode_kwargs["audience"] = audience
    else:
        decode_kwargs["options"] = {"verify_aud": False}

    try:
        return jwt.decode(token, jwk, **decode_kwargs)  # type: ignore[arg-type]
    except JWTError as exc:
        try:
            refreshed = _fetch_jwks(force_refresh=True, issuer=token_issuer)
        except TypeError:
            refreshed = _fetch_jwks(force_refresh=True)
        jwk_refreshed = _find_jwk(refreshed, kid)
        try:
            return jwt.decode(token, jwk_refreshed, **decode_kwargs)  # type: ignore[arg-type]
        except JWTError as exc2:
            raise UnauthorizedException(
                f"Invalid or expired authentication token: {str(exc2)}"
            ) from exc2
        except Exception as exc2:  # pragma: no cover - defensive
            raise UnauthorizedException(
                f"Invalid authentication token: {str(exc2)}"
            ) from exc
    except Exception as exc:  # pragma: no cover - defensive
        raise UnauthorizedException(f"Invalid authentication token: {str(exc)}") from exc


def _verify_hs256_dev_fallback(token: str) -> Dict[str, Any]:
    """Legacy HS256 path, allowed only outside production for dev/test tokens."""
    if _is_production():
        raise UnauthorizedException(
            "Invalid token: HS256 tokens are not accepted in production"
        )
    secret = settings.SUPABASE_JWT_SECRET
    if not secret or _is_dev_secret(secret):
        # In non-production we still allow the historical dev default so the
        # existing test-suite (create_access_token) keeps working, but only
        # when the algorithm is explicitly HS256.
        secret = secret or "dev-secret"
        if _is_production():  # double-guard
            raise UnauthorizedException("Invalid token: JWT secret not configured")
    try:
        return jwt.decode(
            token,
            secret,
            algorithms=["HS256"],
            options={"verify_aud": False},
        )
    except JWTError as e:
        raise UnauthorizedException(
            f"Invalid or expired authentication token: {str(e)}"
        ) from e


def create_access_token(
    data: Dict[str, Any],
    expires_delta: Optional[timedelta] = None,
) -> str:
    """Helper to generate JWT tokens for dev, testing, or mock Supabase auth."""
    to_encode = data.copy()
    role = to_encode.get("role")
    if role:
        app_meta = to_encode.get("app_metadata")
        if not isinstance(app_meta, dict):
            app_meta = {}
        if "role" not in app_meta:
            app_meta["role"] = role
        to_encode["app_metadata"] = app_meta

    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(hours=24)
    to_encode.update({"exp": expire, "iat": now})
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SUPABASE_JWT_SECRET or "dev-secret",
        algorithm="HS256",
    )
    return encoded_jwt



def decode_supabase_jwt(token: str) -> UserContext:
    """
    Decodes and validates a Supabase Auth JWT token.

    Production Supabase projects issue ES256 (JWKS) tokens. Verification uses
    the configured JWKS endpoint, selects the key via the JWT ``kid`` header,
    validates the ES256 signature, issuer, audience, and expiration.

    HS256 verification is retained only as a development/legacy fallback and
    is rejected in production.
    """
    if not token or not token.strip():
        raise UnauthorizedException("Missing authentication token")

    try:
        header = jwt.get_unverified_header(token)
    except JWTError as e:
        raise UnauthorizedException(
            f"Invalid authentication token: {str(e)}"
        ) from e

    alg = str(header.get("alg", "")).upper()
    kid = header.get("kid")

    if alg in _ES_JWKS_ALGORITHMS:
        payload = _verify_with_jwks(token, kid, ["ES256"])
        return _payload_to_user_context(payload)
    if alg in _RSA_JWKS_ALGORITHMS:
        payload = _verify_with_jwks(token, kid, ["RS256"])
        return _payload_to_user_context(payload)
    if alg == "HS256":
        payload = _verify_hs256_dev_fallback(token)
        return _payload_to_user_context(payload)

    # Unknown/unsupported algorithm: fail securely. If a kid is present and a
    # JWKS is configured, attempt ES256/RS256 verification before rejecting.
    if kid and get_jwks_url():
        payload = _verify_with_jwks(token, kid, ["ES256", "RS256"])
        return _payload_to_user_context(payload)
    raise UnauthorizedException(f"Invalid token: unsupported algorithm '{alg or 'none'}'")


def clear_jwks_cache() -> None:
    """Test helper to reset the in-memory JWKS cache."""
    _jwks_cache["keys"] = None
    _jwks_cache["fetched_at"] = 0.0
