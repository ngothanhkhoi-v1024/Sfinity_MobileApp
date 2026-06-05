import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { UserRole } from '../types/enums';
import { placeService } from './place.service';
import type { CreatePlacePhotoDto } from '../dto/place-photo.dto';

const toDate = (val: unknown): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val === 'object' && val !== null && 'toDate' in val) {
    return (val as { toDate: () => Date }).toDate();
  }
  return new Date(val as string | number);
};

async function assertPlaceExists(placeId: string): Promise<void> {
  await placeService.findOne(placeId);
}

export const placePhotoService = {
  async list(placeId: string, limit = 30) {
    await assertPlaceExists(placeId);
    const snapshot = await getDb()
      .collection('place_photos')
      .where('placeId', '==', placeId)
      .get();

    const items = await Promise.all(
      snapshot.docs.map(async (doc) => {
        const data = doc.data() as any;
        let author = null;
        if (data.userId) {
          const userDoc = await getDb().collection('users').doc(data.userId).get();
          if (userDoc.exists) {
            const u = userDoc.data() as any;
            author = { id: userDoc.id, name: u.name };
          }
        }
        return {
          id: doc.id,
          placeId: data.placeId,
          userId: data.userId,
          imageUrl: data.imageUrl,
          caption: data.caption ?? null,
          createdAt: toDate(data.createdAt),
          author,
        };
      }),
    );

    items.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return { items: items.slice(0, limit), photoCount: items.length };
  },

  async create(placeId: string, userId: string, dto: CreatePlacePhotoDto) {
    await assertPlaceExists(placeId);
    const docRef = getDb().collection('place_photos').doc();
    const photo = {
      id: docRef.id,
      placeId,
      userId,
      imageUrl: dto.imageUrl,
      caption: dto.caption ?? null,
      createdAt: new Date(),
    };
    await docRef.set(photo);
    return photo;
  },

  async remove(photoId: string, userId: string, role: UserRole) {
    const doc = await getDb().collection('place_photos').doc(photoId).get();
    if (!doc.exists) {
      throw new HttpError(404, 'Không tìm thấy ảnh', 'Not Found');
    }
    const data = doc.data() as any;
    if (role !== UserRole.ADMIN && data.userId !== userId) {
      throw new HttpError(403, 'Forbidden', 'Forbidden');
    }
    await doc.ref.delete();
    return { success: true };
  },
};
