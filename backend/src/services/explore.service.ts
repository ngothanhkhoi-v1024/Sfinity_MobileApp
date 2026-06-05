import { getDb } from '../lib/firebase';
import { isPubliclyVisible } from '../lib/content-state';
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

};
