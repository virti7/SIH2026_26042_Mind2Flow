"""Regression tests for production integration gaps.

Covers:
- JWKS-based ES256 JWT verification (Supabase Auth production tokens).
- HS256 legacy fallback accepted in dev, rejected in production.
- Supabase Storage signed-URL flow (live signing, 404 handling, dev mock).
"""
import base64
import io
import json
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

import pytest
from jose import jwt

from app.core import security
from app.core.exceptions import UnauthorizedException
from app.core.security import create_access_token, decode_supabase_jwt
from app.storage.service import StorageService


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _make_es256_keypair(kid: str):
    """Generate a P-256 keypair; return (private_pem, public_jwk)."""
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric import ec

    private_key = ec.generate_private_key(ec.SECP256R1())
    numbers = private_key.private_numbers()
    x = numbers.public_numbers.x.to_bytes(32, "big")
    y = numbers.public_numbers.y.to_bytes(32, "big")
    pem = private_key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode("ascii")
    jwk = {
        "kty": "EC",
        "crv": "P-256",
        "x": _b64url(x),
        "y": _b64url(y),
        "kid": kid,
        "alg": "ES256",
        "use": "sig",
    }
    return pem, jwk


def _es256_token(private_pem: str, kid: str, **claims) -> str:
    from app.core.security import get_expected_issuer

    now = datetime.now(timezone.utc)
    payload = {
        "sub": "teacher-es256-uuid-1",
        "email": "teacher1@jharkhand.edu.in",
        "aud": "authenticated",
        "iat": now,
        "exp": now + timedelta(hours=1),
    }
    # Mirror production Supabase tokens: carry the issuer the verifier expects.
    # Resolved dynamically so the fixture matches get_expected_issuer() in any
    # environment; production issuer validation in security.py is untouched.
    expected_issuer = get_expected_issuer()
    if expected_issuer and "iss" not in claims:
        payload["iss"] = expected_issuer
    payload.update(claims)
    return jwt.encode(payload, private_pem, algorithm="ES256", headers={"kid": kid})


class _FakeHttpResponse:
    def __init__(self, payload: dict):
        self._body = json.dumps(payload).encode("utf-8")

    def read(self) -> bytes:
        return self._body

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False


# ---------------------------------------------------------------------------
# JWKS / ES256 verification
# ---------------------------------------------------------------------------

def test_es256_valid_token_accepted(monkeypatch):
    kid = "test-es256-key-1"
    pem, jwk = _make_es256_keypair(kid)
    monkeypatch.setattr(security, "_fetch_jwks", lambda force_refresh=False: [jwk])

    token = _es256_token(pem, kid)
    # The fixture must carry the issuer the verifier expects (when configured).
    expected_issuer = security.get_expected_issuer()
    if expected_issuer:
        unverified = jwt.get_unverified_claims(token)
        assert unverified.get("iss") == expected_issuer
    user = decode_supabase_jwt(token)
    assert user.user_id == "teacher-es256-uuid-1"
    assert user.email == "teacher1@jharkhand.edu.in"


def test_es256_wrong_issuer_rejected(monkeypatch):
    """Production issuer validation stays enforced: a wrong iss must fail."""
    if not security.get_expected_issuer():
        pytest.skip("no expected issuer configured in this environment")
    kid = "test-es256-key-3"
    pem, jwk = _make_es256_keypair(kid)
    monkeypatch.setattr(security, "_fetch_jwks", lambda force_refresh=False: [jwk])

    token = _es256_token(pem, kid, iss="https://wrong-issuer.example.com/auth/v1")
    with pytest.raises(UnauthorizedException):
        decode_supabase_jwt(token)


def test_es256_unknown_kid_rejected(monkeypatch):
    pem, jwk = _make_es256_keypair("real-key")
    monkeypatch.setattr(security, "_fetch_jwks", lambda force_refresh=False: [jwk])

    token = _es256_token(pem, "unknown-key")
    with pytest.raises(UnauthorizedException):
        decode_supabase_jwt(token)


def test_es256_expired_token_rejected(monkeypatch):
    kid = "test-es256-key-2"
    pem, jwk = _make_es256_keypair(kid)
    monkeypatch.setattr(security, "_fetch_jwks", lambda force_refresh=False: [jwk])

    now = datetime.now(timezone.utc)
    token = _es256_token(
        pem, kid, iat=now - timedelta(hours=2), exp=now - timedelta(hours=1)
    )
    with pytest.raises(UnauthorizedException):
        decode_supabase_jwt(token)


def test_es256_jwks_unavailable_fails_closed(monkeypatch):
    """No JWKS configured and non-HS256 token must fail securely, not bypass."""
    monkeypatch.setattr(security, "get_jwks_url", lambda: None)
    # HS256 path is dev-only; use a garbage ES token header instead.
    with pytest.raises(UnauthorizedException):
        decode_supabase_jwt("invalid.jwt.token")


def test_hs256_dev_token_still_accepted_in_dev():
    token = create_access_token({"sub": "dev-user-1", "role": "teacher"})
    user = decode_supabase_jwt(token)
    assert user.user_id == "dev-user-1"


def test_hs256_rejected_in_production(monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    token = create_access_token({"sub": "dev-user-1", "role": "teacher"})
    with pytest.raises(UnauthorizedException):
        decode_supabase_jwt(token)


# ---------------------------------------------------------------------------
# Storage signed URLs
# ---------------------------------------------------------------------------

def test_storage_live_signed_url(monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "SUPABASE_URL", "https://proj.supabase.co")
    monkeypatch.setattr(settings, "SUPABASE_SERVICE_ROLE_KEY", "live-service-key")

    def fake_urlopen(req, timeout=10):
        assert "/storage/v1/object/sign/content/worksheets/a.pdf" in req.full_url
        # Service credentials must travel in headers, never in the URL.
        assert "live-service-key" not in req.full_url
        return _FakeHttpResponse(
            {"signedURL": "/object/sign/content/worksheets/a.pdf?token=signed123"}
        )

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    service = StorageService()
    url = service.get_signed_download_url("content", "worksheets/a.pdf")
    assert url == (
        "https://proj.supabase.co/storage/v1"
        "/object/sign/content/worksheets/a.pdf?token=signed123"
    )


def test_storage_missing_object_raises_not_found(monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "SUPABASE_URL", "https://proj.supabase.co")
    monkeypatch.setattr(settings, "SUPABASE_SERVICE_ROLE_KEY", "live-service-key")

    def fake_urlopen(req, timeout=10):
        raise urllib.error.HTTPError(
            req.full_url, 404, "Not Found", hdrs=None, fp=io.BytesIO(b"{}")
        )

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    service = StorageService()
    with pytest.raises(FileNotFoundError):
        service.get_signed_download_url("content", "missing/file.pdf")


def test_storage_dev_fallback_returns_mock_url(monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setattr(settings, "SUPABASE_SERVICE_ROLE_KEY", "dummy-service-role-key")
    service = StorageService()
    url = service.get_signed_download_url("content", "worksheets/a.pdf")
    assert url.startswith("/api/v1/storage/download/content/worksheets/a.pdf")
