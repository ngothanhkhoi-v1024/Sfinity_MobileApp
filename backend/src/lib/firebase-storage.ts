import { getFirebaseStorage, isFirebaseReady } from './firebase';

export interface ParsedStorageUrl {
  bucket: string;
  path: string;
}

/** Parse Firebase Storage download URL → bucket + object path. */
export function parseFirebaseStorageUrl(url: string): ParsedStorageUrl | null {
  try {
    const parsed = new URL(url);

    if (parsed.hostname === 'firebasestorage.googleapis.com') {
      const bucketMatch = parsed.pathname.match(/^\/v0\/b\/([^/]+)\/o\/(.+)$/);
      if (!bucketMatch) return null;
      return {
        bucket: decodeURIComponent(bucketMatch[1]),
        path: decodeURIComponent(bucketMatch[2]),
      };
    }

    if (parsed.hostname === 'storage.googleapis.com') {
      const parts = parsed.pathname.split('/').filter(Boolean);
      if (parts.length < 2) return null;
      return {
        bucket: parts[0],
        path: parts.slice(1).join('/'),
      };
    }

    return null;
  } catch {
    return null;
  }
}

/** Tải file từ Firebase Storage qua Admin SDK (tin cậy hơn fetch HTTP ngay sau upload). */
export async function downloadFirebaseStorageObject(
  imageUrl: string,
): Promise<{ buffer: Buffer; mimeType: string } | null> {
  if (!isFirebaseReady()) return null;

  const parsed = parseFirebaseStorageUrl(imageUrl);
  if (!parsed) return null;

  try {
    const file = getFirebaseStorage().bucket(parsed.bucket).file(parsed.path);
    const [buffer] = await file.download();
    const [metadata] = await file.getMetadata();
    const rawType = metadata.contentType?.split(';')[0]?.trim() ?? 'image/jpeg';
    const mimeType = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(rawType)
      ? rawType
      : 'image/jpeg';
    return { buffer, mimeType };
  } catch (err) {
    console.warn('[firebase-storage] Download failed:', parsed.path, err);
    return null;
  }
}

/** Xóa file trên Firebase Storage từ download URL (best-effort). */
export async function deleteFirebaseStorageObject(imageUrl: string): Promise<void> {
  if (!isFirebaseReady()) return;

  const parsed = parseFirebaseStorageUrl(imageUrl);
  if (!parsed) return;

  try {
    const bucket = getFirebaseStorage().bucket(parsed.bucket);
    await bucket.file(parsed.path).delete({ ignoreNotFound: true });
  } catch (err) {
    console.warn('[firebase-storage] Failed to delete object:', parsed.path, err);
  }
}
