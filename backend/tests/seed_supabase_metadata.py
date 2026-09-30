import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select
from app.db.session import AsyncSessionLocal
from app.db.models.school import Language, School, Teacher
from app.db.models.language_pack import LanguagePack, ModelVersion

async def seed():
    async with AsyncSessionLocal() as session:
        # 1. Languages
        langs = [
            {"code": "hi", "name": "Hindi", "script": "Devanagari"},
            {"code": "ho", "name": "Ho", "script": "Warang Chiti"},
            {"code": "unr", "name": "Mundari", "script": "Baniuri"},
            {"code": "sat", "name": "Santali", "script": "Ol Chiki"},
        ]
        for l in langs:
            res = await session.execute(select(Language).where(Language.code == l["code"]))
            if not res.scalar_one_or_none():
                session.add(Language(**l))

        # 2. Language Packs
        packs = [
            {
                "language_code": "ho",
                "version": "1.0.0",
                "model_version": "1.0.0",
                "content_version": "1",
                "package_size": 18 * 1024 * 1024,
                "checksum": "sha256:d41d8cd98f00b204e9800998ecf8427e",
                "download_url": "https://zowjbmjehuyfwjjcgzqo.supabase.co/storage/v1/object/sign/language-packs/ho_1.0.0.tar.gz",
                "release_status": "RELEASED",
                "compatible_app_version": "1.0.0",
                "min_android_version": 26,
            },
            {
                "language_code": "unr",
                "version": "1.0.0",
                "model_version": "1.0.0",
                "content_version": "1",
                "package_size": 22 * 1024 * 1024,
                "checksum": "sha256:e3b0c44298fc1c149afbf4c8996fb924",
                "download_url": "https://zowjbmjehuyfwjjcgzqo.supabase.co/storage/v1/object/sign/language-packs/mundari_1.0.0.tar.gz",
                "release_status": "RELEASED",
                "compatible_app_version": "1.0.0",
                "min_android_version": 26,
            },
            {
                "language_code": "sat",
                "version": "1.0.0",
                "model_version": "1.0.0",
                "content_version": "1",
                "package_size": 20 * 1024 * 1024,
                "checksum": "sha256:a6b22552d41d8cd98f00b204e9800998",
                "download_url": "https://zowjbmjehuyfwjjcgzqo.supabase.co/storage/v1/object/sign/language-packs/santali_1.0.0.tar.gz",
                "release_status": "RELEASED",
                "compatible_app_version": "1.0.0",
                "min_android_version": 26,
            },
        ]
        for p in packs:
            res = await session.execute(
                select(LanguagePack).where(
                    LanguagePack.language_code == p["language_code"],
                    LanguagePack.version == p["version"]
                )
            )
            if not res.scalar_one_or_none():
                session.add(LanguagePack(**p))

        # 3. Model Versions
        models = [
            {
                "model_name": "conformer_asr_ho",
                "model_type": "ASR",
                "language_code": "ho",
                "version": "1.0.0",
                "checksum": "sha256:asr_ho_checksum_12345",
                "size_bytes": 45 * 1024 * 1024,
                "download_url": "https://zowjbmjehuyfwjjcgzqo.supabase.co/storage/v1/object/sign/models/asr_ho.onnx",
                "compatibility": "Android 8+",
                "release_status": "RELEASED",
            },
            {
                "model_name": "indictrans2_nmt_ho_hi",
                "model_type": "NMT",
                "language_code": "ho",
                "version": "1.0.0",
                "checksum": "sha256:nmt_ho_checksum_67890",
                "size_bytes": 85 * 1024 * 1024,
                "download_url": "https://zowjbmjehuyfwjjcgzqo.supabase.co/storage/v1/object/sign/models/nmt_ho.onnx",
                "compatibility": "Android 8+",
                "release_status": "RELEASED",
            },
            {
                "model_name": "vits_tts_ho",
                "model_type": "TTS",
                "language_code": "ho",
                "version": "1.0.0",
                "checksum": "sha256:tts_ho_checksum_abcde",
                "size_bytes": 35 * 1024 * 1024,
                "download_url": "https://zowjbmjehuyfwjjcgzqo.supabase.co/storage/v1/object/sign/models/tts_ho.onnx",
                "compatibility": "Android 8+",
                "release_status": "RELEASED",
            },
        ]
        for m in models:
            res = await session.execute(
                select(ModelVersion).where(
                    ModelVersion.model_name == m["model_name"],
                    ModelVersion.version == m["version"]
                )
            )
            if not res.scalar_one_or_none():
                session.add(ModelVersion(**m))

        await session.commit()
        print(">>> SEEDED SUPABASE POSTGRESQL: Languages, LanguagePacks, Models <<<")

if __name__ == "__main__":
    asyncio.run(seed())
