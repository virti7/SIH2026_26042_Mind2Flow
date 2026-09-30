from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.admin.schemas import AdminActionResponse, PackPublicationRequest
from app.core.dependencies import get_db, require_admin
from app.core.exceptions import NotFoundException
from app.core.security import UserContext
from app.db.models.language_pack import LanguagePack

router = APIRouter(prefix="/admin", tags=["Administration"])


@router.post("/publish-pack", response_model=AdminActionResponse, summary="Update Language Pack Publication Status (Admin only)")
async def publish_language_pack(
    req: PackPublicationRequest,
    db: AsyncSession = Depends(get_db),
    admin: UserContext = Depends(require_admin),
):
    pack = await db.get(LanguagePack, req.pack_id)
    if not pack:
        raise NotFoundException("LanguagePack", req.pack_id)

    pack.release_status = req.release_status.upper()
    await db.commit()

    return AdminActionResponse(
        success=True,
        message=f"Language pack '{pack.language_code}' status updated to {pack.release_status}",
    )
