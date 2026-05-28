import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { documentService } from './document.service';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

export const favoritesService = {
  async findByUser(userId: string) {
    const snapshot = await getDb()
      .collection('favorites')
      .where('userId', '==', userId)
      .get();

    const list = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as any));

    // Sort by createdAt desc in memory
    list.sort((a, b) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());

    // Resolve documents for the favorite items
    const resolvedList = await Promise.all(
      list.map(async (fav) => {
        let document = null;
        try {
          document = await documentService.findOne(fav.documentId);
        } catch (err) {
          // Document might have been deleted, ignore
        }
        return {
          id: fav.id,
          userId: fav.userId,
          documentId: fav.documentId,
          createdAt: toDate(fav.createdAt),
          document,
        };
      }),
    );

    // Filter out deleted documents
    return resolvedList.filter((item) => item.document !== null);
  },

  async add(userId: string, documentId: string) {
    const document = await documentService.findOne(documentId); // Throws 404 if document not found

    const favId = `${userId}_${documentId}`;
    const favRef = getDb().collection('favorites').doc(favId);
    const doc = await favRef.get();

    if (doc.exists) {
      throw new HttpError(409, 'Đã có trong yêu thích', 'Conflict');
    }

    const newFav = {
      id: favId,
      userId,
      documentId,
      createdAt: new Date(),
    };

    await favRef.set(newFav);

    return {
      ...newFav,
      document,
    };
  },

  async remove(userId: string, documentId: string) {
    const favId = `${userId}_${documentId}`;
    const favRef = getDb().collection('favorites').doc(favId);
    const doc = await favRef.get();

    if (!doc.exists) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    await favRef.delete();
    return { success: true };
  },
};
