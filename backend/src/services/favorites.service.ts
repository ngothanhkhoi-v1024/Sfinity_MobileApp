import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { contentService } from './content.service';

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

    // Resolve contents for the favorite items
    const resolvedList = await Promise.all(
      list.map(async (fav) => {
        let content = null;
        try {
          content = await contentService.findOne(fav.contentId);
        } catch (err) {
          // Content might have been deleted, ignore
        }
        return {
          id: fav.id,
          userId: fav.userId,
          contentId: fav.contentId,
          createdAt: toDate(fav.createdAt),
          content,
        };
      }),
    );

    // Filter out deleted contents
    return resolvedList.filter((item) => item.content !== null);
  },

  async add(userId: string, contentId: string) {
    const content = await contentService.findOne(contentId); // Throws 404 if content not found

    const favId = `${userId}_${contentId}`;
    const favRef = getDb().collection('favorites').doc(favId);
    const doc = await favRef.get();

    if (doc.exists) {
      throw new HttpError(409, 'Đã có trong yêu thích', 'Conflict');
    }

    const newFav = {
      id: favId,
      userId,
      contentId,
      createdAt: new Date(),
    };

    await favRef.set(newFav);

    return {
      ...newFav,
      content,
    };
  },

  async remove(userId: string, contentId: string) {
    const favId = `${userId}_${contentId}`;
    const favRef = getDb().collection('favorites').doc(favId);
    const doc = await favRef.get();

    if (!doc.exists) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    await favRef.delete();
    return { success: true };
  },
};
