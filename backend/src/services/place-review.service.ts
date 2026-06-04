import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { placeService } from './place.service';
import type { CreatePlaceReviewDto } from '../dto/place-review.dto';

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

export const placeReviewService = {
  async getSummary(placeId: string) {
    await assertPlaceExists(placeId);
    const snapshot = await getDb()
      .collection('place_reviews')
      .where('placeId', '==', placeId)
      .get();

    const ratings = snapshot.docs
      .map((doc) => doc.data().rating as number)
      .filter((r) => typeof r === 'number' && r >= 1 && r <= 5);

    const reviewCount = ratings.length;
    const avgRating =
      reviewCount > 0
        ? Math.round((ratings.reduce((a, b) => a + b, 0) / reviewCount) * 10) / 10
        : null;

    return { avgRating, reviewCount };
  },

  async list(placeId: string, limit = 20) {
    await assertPlaceExists(placeId);
    const snapshot = await getDb()
      .collection('place_reviews')
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
          rating: data.rating,
          comment: data.comment ?? null,
          createdAt: toDate(data.createdAt),
          updatedAt: toDate(data.updatedAt),
          author,
        };
      }),
    );

    items.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    const summary = await placeReviewService.getSummary(placeId);
    return { ...summary, items: items.slice(0, limit) };
  },

  async upsert(placeId: string, userId: string, dto: CreatePlaceReviewDto) {
    await assertPlaceExists(placeId);

    const existing = await getDb()
      .collection('place_reviews')
      .where('placeId', '==', placeId)
      .where('userId', '==', userId)
      .limit(1)
      .get();

    const payload = {
      placeId,
      userId,
      rating: dto.rating,
      comment: dto.comment ?? null,
      updatedAt: new Date(),
    };

    if (!existing.empty) {
      const docRef = existing.docs[0].ref;
      await docRef.update(payload);
      const updated = await docRef.get();
      const summary = await placeReviewService.getSummary(placeId);
      return {
        review: { id: updated.id, ...updated.data(), createdAt: toDate(updated.data()?.createdAt) },
        ...summary,
      };
    }

    const docRef = getDb().collection('place_reviews').doc();
    await docRef.set({
      ...payload,
      createdAt: new Date(),
    });
    const created = await docRef.get();
    const summary = await placeReviewService.getSummary(placeId);
    return {
      review: { id: created.id, ...created.data(), createdAt: toDate(created.data()?.createdAt) },
      ...summary,
    };
  },
};
