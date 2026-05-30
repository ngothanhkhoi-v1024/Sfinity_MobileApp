import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { documentService } from './document.service';
import type { CreateDocumentReviewDto } from '../dto/document-review.dto';

const toDate = (val: unknown): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val === 'object' && val !== null && 'toDate' in val) {
    return (val as { toDate: () => Date }).toDate();
  }
  return new Date(val as string | number);
};

async function assertDocumentExists(documentId: string): Promise<void> {
  const doc = await documentService.findOne(documentId);
  if ((doc.type ?? 'document') !== 'document') {
    throw new HttpError(400, 'documentId không hợp lệ', 'Bad Request');
  }
}

export const documentReviewService = {
  async getSummary(documentId: string) {
    await assertDocumentExists(documentId);
    const snapshot = await getDb()
      .collection('document_reviews')
      .where('documentId', '==', documentId)
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

  async list(documentId: string, limit = 20) {
    await assertDocumentExists(documentId);
    const snapshot = await getDb()
      .collection('document_reviews')
      .where('documentId', '==', documentId)
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
          documentId: data.documentId,
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
    const summary = await documentReviewService.getSummary(documentId);
    return { ...summary, items: items.slice(0, limit) };
  },

  async upsert(documentId: string, userId: string, dto: CreateDocumentReviewDto) {
    await assertDocumentExists(documentId);

    const existing = await getDb()
      .collection('document_reviews')
      .where('documentId', '==', documentId)
      .where('userId', '==', userId)
      .limit(1)
      .get();

    const payload = {
      documentId,
      userId,
      rating: dto.rating,
      comment: dto.comment ?? null,
      updatedAt: new Date(),
    };

    if (!existing.empty) {
      const docRef = existing.docs[0].ref;
      await docRef.update(payload);
      const updated = await docRef.get();
      const summary = await documentReviewService.getSummary(documentId);
      return {
        review: { id: updated.id, ...updated.data(), createdAt: toDate(updated.data()?.createdAt) },
        ...summary,
      };
    }

    const docRef = getDb().collection('document_reviews').doc();
    await docRef.set({
      ...payload,
      createdAt: new Date(),
    });
    const created = await docRef.get();
    const summary = await documentReviewService.getSummary(documentId);
    return {
      review: { id: created.id, ...created.data(), createdAt: toDate(created.data()?.createdAt) },
      ...summary,
    };
  },

  async remove(documentId: string, userId: string) {
    await assertDocumentExists(documentId);
    const existing = await getDb()
      .collection('document_reviews')
      .where('documentId', '==', documentId)
      .where('userId', '==', userId)
      .limit(1)
      .get();

    if (existing.empty) {
      throw new HttpError(404, 'Không tìm thấy đánh giá của bạn', 'Not Found');
    }

    await existing.docs[0].ref.delete();
    return documentReviewService.getSummary(documentId);
  },
};
