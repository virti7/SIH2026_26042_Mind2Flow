import asyncio
import os
import sys
import httpx

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings

async def test_supabase_storage():
    headers = {
        "apikey": settings.SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_SERVICE_ROLE_KEY}",
    }
    base_url = settings.SUPABASE_URL
    bucket_name = "content"

    async with httpx.AsyncClient() as client:
        # 1. Check / Create bucket
        r_buckets = await client.get(f"{base_url}/storage/v1/bucket", headers=headers)
        assert r_buckets.status_code == 200, f"Bucket list failed: {r_buckets.text}"
        existing_buckets = [b["name"] for b in r_buckets.json()]
        print(f"Existing Supabase Storage buckets: {existing_buckets}")

        if bucket_name not in existing_buckets:
            print(f"Creating private bucket '{bucket_name}'...")
            r_create = await client.post(
                f"{base_url}/storage/v1/bucket",
                json={"id": bucket_name, "name": bucket_name, "public": False},
                headers=headers
            )
            assert r_create.status_code in (200, 201), f"Create bucket failed: {r_create.text}"
            print(f"Bucket '{bucket_name}' created successfully (public=False).")

        # Also ensure language-packs and models buckets exist
        for b_name in ["language-packs", "models"]:
            if b_name not in existing_buckets:
                await client.post(
                    f"{base_url}/storage/v1/bucket",
                    json={"id": b_name, "name": b_name, "public": False},
                    headers=headers
                )
                print(f"Created private bucket '{b_name}' (public=False).")

        # 2. Upload small test object
        test_path = "verification/e2e_test_note.txt"
        test_content = b"Maatribhasha Real Supabase Storage Verification 2026"
        upload_headers = {
            **headers,
            "Content-Type": "text/plain",
            "x-upsert": "true",
        }
        r_upload = await client.post(
            f"{base_url}/storage/v1/object/{bucket_name}/{test_path}",
            content=test_content,
            headers=upload_headers,
        )
        assert r_upload.status_code == 200, f"Upload failed: {r_upload.text}"
        print(f"Uploaded test object to {bucket_name}/{test_path}")

        # 3. Verify object exists
        r_list = await client.post(
            f"{base_url}/storage/v1/object/list/{bucket_name}",
            json={"prefix": "verification", "limit": 10},
            headers=headers,
        )
        assert r_list.status_code == 200, f"Object list failed: {r_list.text}"
        files = [f["name"] for f in r_list.json()]
        assert "e2e_test_note.txt" in files, f"Object not found in list: {files}"
        print(f"Verified object exists in bucket: {files}")

        # 4. Generate signed download URL (valid for 60 seconds)
        r_sign = await client.post(
            f"{base_url}/storage/v1/object/sign/{bucket_name}/{test_path}",
            json={"expiresIn": 60},
            headers=headers,
        )
        assert r_sign.status_code == 200, f"Sign URL failed: {r_sign.text}"
        signed_url_path = r_sign.json()["signedURL"]
        full_signed_url = f"{base_url}/storage/v1{signed_url_path}"
        print("Generated signed URL successfully")

        # 5. Access object using the signed URL
        r_download = await client.get(full_signed_url)
        assert r_download.status_code == 200, f"Signed download failed: {r_download.status_code}"
        assert r_download.content == test_content, "Downloaded content mismatch"
        print("Successfully downloaded & verified object content via signed URL")

        # 6. Verify unauthorized request (no token/signature) is rejected (400 or 404 or 401)
        public_url = f"{base_url}/storage/v1/object/public/{bucket_name}/{test_path}"
        r_unauth = await client.get(public_url)
        assert r_unauth.status_code in (400, 403, 404), f"Private object was publicly accessible: {r_unauth.status_code}"
        print(f"Verified private bucket security: direct public access rejected ({r_unauth.status_code})")

        # 7. Clean up test object
        r_del = await client.request(
            "DELETE",
            f"{base_url}/storage/v1/object/{bucket_name}",
            json={"prefixes": [test_path]},
            headers=headers,
        )
        assert r_del.status_code == 200, f"Delete failed: {r_del.text}"
        print("Cleaned up temporary test object")

        print(">>> REAL SUPABASE STORAGE VERIFICATION: 100% PASSED <<<")

if __name__ == "__main__":
    asyncio.run(test_supabase_storage())
