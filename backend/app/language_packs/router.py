from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, require_admin
from app.core.exceptions import NotFoundException
from app.core.security import UserContext
from app.db.models.language_pack import LanguagePack
from app.db.models.school import Language
from app.language_packs.schemas import (
    LanguagePackCreate,
    LanguagePackManifest,
    LanguagePackResponse,
    LanguagePackVersionCheck,
)

router = APIRouter(prefix="/language-packs", tags=["Language Packs"])


@router.get("", response_model=List[LanguagePackResponse], summary="List Language Packs")
async def list_language_packs(
    language_code: Optional[str] = Query(None),
    status: Optional[str] = Query("RELEASED"),
    db: AsyncSession = Depends(get_db),
):
    query = select(LanguagePack)
    if language_code:
        query = query.where(LanguagePack.language_code == language_code.lower())
    if status:
        query = query.where(LanguagePack.release_status == status)

    res = await db.execute(query.order_by(LanguagePack.created_at.desc()))
    return res.scalars().all()


@router.get("/{language}", response_model=LanguagePackResponse, summary="Get Latest Language Pack for Language")
async def get_language_pack(
    language: str,
    db: AsyncSession = Depends(get_db),
):
    res = await db.execute(
        select(LanguagePack)
        .where(
            LanguagePack.language_code == language.lower(),
            LanguagePack.release_status == "RELEASED",
        )
        .order_by(LanguagePack.created_at.desc())
    )
    pack = res.scalar_one_or_none()
    if not pack:
        raise NotFoundException("LanguagePack", language)
    return pack


@router.get("/{language}/manifest", response_model=LanguagePackManifest, summary="Get Language Pack Manifest")
async def get_pack_manifest(
    language: str,
    db: AsyncSession = Depends(get_db),
):
    """
    Returns the complete update manifest for an offline language pack so the client device
    can verify whether it needs an update without downloading the entire binary archive.
    """
    res = await db.execute(
        select(LanguagePack)
        .where(
            LanguagePack.language_code == language.lower(),
            LanguagePack.release_status == "RELEASED",
        )
        .order_by(LanguagePack.created_at.desc())
    )
    pack = res.scalar_one_or_none()
    if not pack:
        raise NotFoundException("LanguagePack", language)

    return LanguagePackManifest(
        pack_id=pack.id,
        language=pack.language_code,
        version=pack.version,
        model_version=pack.model_version,
        content_version=pack.content_version,
        package_size_bytes=pack.package_size,
        checksum_sha256=pack.checksum,
        download_url=pack.download_url,
        release_status=pack.release_status,
        compatible_app_version=pack.compatible_app_version,
        min_android_version=pack.min_android_version,
        assets={
            "vocabulary": f"/content/{pack.language_code}/vocab.json",
            "verified_phrases": f"/content/{pack.language_code}/phrases.json",
            "models": {
                "nmt": f"/models/nmt/{pack.language_code}.onnx",
                "tts": f"/models/tts/{pack.language_code}.onnx",
            },
        },
        created_at=pack.created_at,
    )


@router.get("/{language}/version", response_model=LanguagePackVersionCheck, summary="Check Language Pack Version")
async def check_pack_version(
    language: str,
    client_version: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    """
    Lightweight version check endpoint. Compares client version against server version.
    """
    res = await db.execute(
        select(LanguagePack)
        .where(
            LanguagePack.language_code == language.lower(),
            LanguagePack.release_status == "RELEASED",
        )
        .order_by(LanguagePack.created_at.desc())
    )
    pack = res.scalar_one_or_none()
    if not pack:
        raise NotFoundException("LanguagePack", language)

    update_available = client_version is None or client_version != pack.version

    return LanguagePackVersionCheck(
        language=pack.language_code,
        current_server_version=pack.version,
        client_version=client_version,
        update_available=update_available,
        download_url=pack.download_url if update_available else None,
        checksum=pack.checksum if update_available else None,
        package_size_bytes=pack.package_size if update_available else None,
    )


@router.post("", response_model=LanguagePackResponse, summary="Publish New Language Pack (Admin only)")
async def create_language_pack(
    req: LanguagePackCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: UserContext = Depends(require_admin),
):
    # Lookup language id
    lang_res = await db.execute(select(Language).where(Language.code == req.language_code.lower()))
    lang = lang_res.scalar_one_or_none()

    pack = LanguagePack(
        language_id=lang.id if lang else None,
        language_code=req.language_code.lower(),
        version=req.version,
        model_version=req.model_version,
        content_version=req.content_version,
        package_size=req.package_size,
        checksum=req.checksum,
        download_url=req.download_url,
        release_status=req.release_status,
        compatible_app_version=req.compatible_app_version,
        min_android_version=req.min_android_version,
    )
    db.add(pack)
    await db.commit()
    await db.refresh(pack)
    return pack
