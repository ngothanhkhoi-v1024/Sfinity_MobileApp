import { getDb } from '../lib/firebase';
import { isPubliclyVisible } from '../lib/content-state';
import { UserRole } from '../types/enums';
import { placeService } from './place.service';
import { documentService } from './document.service';

const toDate = (val: unknown): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val === 'object' && val !== null && 'toDate' in val) {
    return (val as { toDate: () => Date }).toDate();
  }
  return new Date(val as string | number);
};

function startOfWeekMonday(date = new Date()): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  const day = d.getDay();
  const diff = day === 0 ? 6 : day - 1;
  d.setDate(d.getDate() - diff);
  return d;
}

function dayLabels(): string[] {
  return ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
}

function bucketByWeekDay(events: { createdAt: Date }[], weekStart: Date) {
  const buckets = Array.from({ length: 7 }, () => 0);
  for (const event of events) {
    const created = toDate(event.createdAt);
    const diffDays = Math.floor(
      (created.getTime() - weekStart.getTime()) / (24 * 60 * 60 * 1000),
    );
    if (diffDays >= 0 && diffDays < 7) {
      buckets[diffDays] += 1;
    }
  }
  return buckets;
}

export const exploreService = {
  async getFeatured() {
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);

    const [recentCheckinsSnap, allCheckinsSnap, documentsRes] = await Promise.all([
      getDb()
        .collection('place_checkins')
        .where('createdAt', '>=', weekAgo)
        .get(),
      getDb().collection('place_checkins').get(),
      documentService.findAll({
        publishedOnly: true,
        limit: 200,
        page: 1,
      }),
    ]);

    const checkinCounts = new Map<string, number>();
    const recentOnly = recentCheckinsSnap.docs.length > 0;
    const sourceDocs = recentOnly ? recentCheckinsSnap.docs : allCheckinsSnap.docs;

    for (const doc of sourceDocs) {
      const placeId = doc.data().placeId as string;
      if (!placeId) continue;
      checkinCounts.set(placeId, (checkinCounts.get(placeId) ?? 0) + 1);
    }

    const sortedPlaceIds = [...checkinCounts.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8)
      .map(([id]) => id);

    const trendingPlaces = (
      await Promise.all(
        sortedPlaceIds.map(async (placeId) => {
          try {
            const place = await placeService.findOne(placeId);
            if (!isPubliclyVisible(place)) return null;
            return {
              ...place,
              recentCheckInCount: checkinCounts.get(placeId) ?? 0,
              isRecentTrend: recentOnly,
            };
          } catch {
            return null;
          }
        }),
      )
    ).filter(Boolean);

    const trendingDocuments = [...documentsRes.items]
      .filter((item: any) => item.type !== 'place')
      .sort(
        (a: any, b: any) =>
          (b.downloadsCount ?? 0) - (a.downloadsCount ?? 0),
      )
      .slice(0, 8)
      .map((item: any) => ({
        id: item.id,
        title: item.title,
        downloadsCount: item.downloadsCount ?? 0,
        type: 'document',
        category: item.category ?? null,
        author: item.author ?? null,
      }));

    return { trendingPlaces, trendingDocuments };
  },

  async getWeeklyStats(userId: string) {
    const weekStart = startOfWeekMonday();

    const [checkinsSnap, downloadsSnap] = await Promise.all([
      getDb()
        .collection('place_checkins')
        .where('userId', '==', userId)
        .where('createdAt', '>=', weekStart)
        .get(),
      getDb()
        .collection('document_download_logs')
        .where('userId', '==', userId)
        .where('createdAt', '>=', weekStart)
        .get(),
    ]);

    const checkins = checkinsSnap.docs.map((d) => ({
      createdAt: toDate(d.data().createdAt),
    }));
    const downloads = downloadsSnap.docs.map((d) => ({
      createdAt: toDate(d.data().createdAt),
    }));

    const placeBuckets = bucketByWeekDay(checkins, weekStart);
    const downloadBuckets = bucketByWeekDay(downloads, weekStart);
    const labels = dayLabels();

    return {
      weekStart: weekStart.toISOString(),
      totalPlaces: checkins.length,
      totalDownloads: downloads.length,
      days: labels.map((label, i) => ({
        label,
        places: placeBuckets[i],
        downloads: downloadBuckets[i],
      })),
    };
  },

  async getTopUsers(limit = 10) {
    const [documentsSnap, placesSnap, checkinsSnap] = await Promise.all([
      getDb().collection('documents').get(),
      getDb().collection('places').get(),
      getDb().collection('place_checkins').get(),
    ]);

    type UserStats = {
      documentsCount: number;
      placesCount: number;
      downloadsCount: number;
      checkinsCount: number;
      score: number;
    };

    const placeAuthors = new Map<string, string>();
    const userStats = new Map<string, UserStats>();

    const ensureStats = (userId: string): UserStats => {
      if (!userStats.has(userId)) {
        userStats.set(userId, {
          documentsCount: 0,
          placesCount: 0,
          downloadsCount: 0,
          checkinsCount: 0,
          score: 0,
        });
      }
      return userStats.get(userId)!;
    };

    for (const doc of placesSnap.docs) {
      const data = doc.data();
      if (!isPubliclyVisible(data)) continue;
      const authorId = data.authorId as string;
      if (!authorId) continue;
      placeAuthors.set(doc.id, authorId);
      ensureStats(authorId).placesCount += 1;
    }

    for (const doc of documentsSnap.docs) {
      const data = doc.data();
      if (!isPubliclyVisible(data)) continue;
      if (data.type === 'place') continue;
      const authorId = data.authorId as string;
      if (!authorId) continue;
      const stats = ensureStats(authorId);
      stats.documentsCount += 1;
      stats.downloadsCount += (data.downloadsCount as number) ?? 0;
    }

    for (const doc of checkinsSnap.docs) {
      const placeId = doc.data().placeId as string;
      if (!placeId) continue;
      const authorId = placeAuthors.get(placeId);
      if (!authorId) continue;
      ensureStats(authorId).checkinsCount += 1;
    }

    for (const stats of userStats.values()) {
      stats.score =
        stats.downloadsCount +
        stats.checkinsCount +
        stats.documentsCount * 5 +
        stats.placesCount * 10;
    }

    const sorted = [...userStats.entries()]
      .filter(([, stats]) => stats.score > 0)
      .sort((a, b) => b[1].score - a[1].score)
      .slice(0, limit);

    const users = (
      await Promise.all(
        sorted.map(async ([userId, stats]) => {
          const userDoc = await getDb().collection('users').doc(userId).get();
          if (!userDoc.exists) return null;
          const user = userDoc.data()!;
          if (user.role === UserRole.ADMIN) return null;

          return {
            id: userId,
            name: (user.name as string) ?? 'User',
            avatar: (user.avatar as string) ?? null,
            documentsCount: stats.documentsCount,
            placesCount: stats.placesCount,
            downloadsCount: stats.downloadsCount,
            checkinsCount: stats.checkinsCount,
            score: stats.score,
          };
        }),
      )
    ).filter(Boolean);

    return {
      users: users.map((user, index) => ({
        ...user,
        rank: index + 1,
      })),
    };
  },

};
