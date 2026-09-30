import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_check(client: AsyncClient):
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["database"] == "healthy"
    assert "service" in data
    assert "timestamp" in data
    # Verify no credentials leaked
    assert "key" not in str(data).lower()
    assert "secret" not in str(data).lower()


@pytest.mark.asyncio
async def test_root_endpoint(client: AsyncClient):
    response = await client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "running"
    assert data["docs"] == "/docs"
    assert data["health"] == "/health"
