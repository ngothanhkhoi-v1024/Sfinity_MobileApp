import { getDb } from '../lib/firebase';
import { isPubliclyVisible } from '../lib/content-state';
import { UserRole, ReportStatus } from '../types/enums';

const toDate = (val: unknown): Date => {
  if (!val) return new Date(0);
  if (val instanceof Date) return val;
  if (typeof val === 'object' && val !== null && 'toDate' in val && typeof (val as { toDate: () => Date }).toDate === 'function') {
    return (val as { toDate: () => Date }).toDate();
  }
  return new Date(val as string | number);
};

export interface DashboardDateRange {
  from: Date;
  to: Date;
}

export interface DashboardActivityDay {
  date: string;
  users: number;
  documents: number;
  places: number;
  feedback: number;
}

function startOfDay(d: Date): Date {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

function endOfDay(d: Date): Date {
  const x = new Date(d);
  x.setHours(23, 59, 59, 999);
  return x;
}

function formatDayKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function isInRange(date: Date, range?: DashboardDateRange): boolean {
  if (!range) return true;
  const t = date.getTime();
  return t >= range.from.getTime() && t <= range.to.getTime();
}

function defaultActivityRange(): DashboardDateRange {
  const to = endOfDay(new Date());
  const from = startOfDay(new Date());
  from.setDate(from.getDate() - 13);
  return { from, to };
}

function resolveActivityRange(range?: DashboardDateRange): DashboardDateRange {
  return range ?? defaultActivityRange();
}

function buildDayBuckets(range: DashboardDateRange): Map<string, DashboardActivityDay> {
  const buckets = new Map<string, DashboardActivityDay>();
  const cur = startOfDay(range.from);
  const end = startOfDay(range.to);

  while (cur.getTime() <= end.getTime()) {
    const key = formatDayKey(cur);
    buckets.set(key, { date: key, users: 0, documents: 0, places: 0, feedback: 0 });
    cur.setDate(cur.getDate() + 1);
  }

  return buckets;
}

function bumpActivity(
  buckets: Map<string, DashboardActivityDay>,
  date: Date,
  field: keyof Omit<DashboardActivityDay, 'date'>,
) {
  const key = formatDayKey(date);
  const bucket = buckets.get(key);
  if (bucket) bucket[field] += 1;
}

export function parseDashboardDateRange(
  fromStr?: string,
  toStr?: string,
): DashboardDateRange | undefined {
  if (!fromStr && !toStr) return undefined;

  const from = fromStr ? startOfDay(new Date(fromStr)) : startOfDay(new Date(0));
  const to = toStr ? endOfDay(new Date(toStr)) : endOfDay(new Date());

  if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
    throw new Error('Invalid date range');
  }
  if (from.getTime() > to.getTime()) {
    throw new Error('from must be before to');
  }

  return { from, to };
}

export const dashboardService = {
  async getStats(range?: DashboardDateRange) {
    const db = getDb();
    const activityRange = resolveActivityRange(range);
    const activityBuckets = buildDayBuckets(activityRange);

    const [
      usersSnap,
      adminsSnap,
      documentsSnap,
      placesSnap,
      categoriesSnap,
      feedbackSnap,
      reportsSnap,
    ] = await Promise.all([
      db.collection('users').get(),
      db.collection('users').where('role', '==', UserRole.ADMIN).get(),
      db.collection('documents').get(),
      db.collection('places').get(),
      db.collection('categories').get(),
      db.collection('feedbacks').get(),
      db.collection('reports').get(),
    ]);

    const users = usersSnap.docs
      .map((d) => d.data() as Record<string, unknown>)
      .filter((u) => u.role === UserRole.USER && isInRange(toDate(u.createdAt), range));

    const admins = adminsSnap.docs
      .map((d) => d.data())
      .filter((u) => isInRange(toDate(u.createdAt), range));

    const documents = documentsSnap.docs
      .map((d) => d.data())
      .filter((doc) => isInRange(toDate(doc.createdAt), range));

    const places = placesSnap.docs
      .map((d) => d.data())
      .filter((p) => isInRange(toDate(p.createdAt), range));

    const categories = categoriesSnap.docs
      .map((d) => d.data())
      .filter((c) => isInRange(toDate(c.createdAt), range));

    const feedbacks = feedbackSnap.docs
      .map((d) => d.data())
      .filter((f) => isInRange(toDate(f.createdAt), range));

    const reports = reportsSnap.docs
      .map((d) => d.data())
      .filter((r) => isInRange(toDate(r.createdAt), range));

    const publishedDocuments = documents.filter((doc) => isPubliclyVisible(doc)).length;
    const publishedPlaces = places.filter((p) => isPubliclyVisible(p)).length;

    const documentCount = documents.length;
    const placeCount = places.length;
    const contents = documentCount + placeCount;
    const publishedContents = publishedDocuments + publishedPlaces;
    const draftContents = contents - publishedContents;

    const pendingFeedback = feedbacks.filter((f) => f.resolved === false).length;
    const pendingReports = reports.filter((r) => r.status === ReportStatus.PENDING).length;

    for (const u of usersSnap.docs) {
      const data = u.data();
      if (data.role !== UserRole.USER) continue;
      const created = toDate(data.createdAt);
      if (isInRange(created, activityRange)) bumpActivity(activityBuckets, created, 'users');
    }

    for (const doc of documentsSnap.docs) {
      const created = toDate(doc.data().createdAt);
      if (isInRange(created, activityRange)) bumpActivity(activityBuckets, created, 'documents');
    }

    for (const place of placesSnap.docs) {
      const created = toDate(place.data().createdAt);
      if (isInRange(created, activityRange)) bumpActivity(activityBuckets, created, 'places');
    }

    for (const fb of feedbackSnap.docs) {
      const created = toDate(fb.data().createdAt);
      if (isInRange(created, activityRange)) bumpActivity(activityBuckets, created, 'feedback');
    }

    const activityByDay = Array.from(activityBuckets.values());

    return {
      users: users.length,
      admins: admins.length,
      documents: documentCount,
      publishedDocuments,
      draftDocuments: documentCount - publishedDocuments,
      places: placeCount,
      publishedPlaces,
      contents,
      publishedContents,
      draftContents,
      categories: categories.length,
      feedback: feedbacks.length,
      pendingFeedback,
      pendingReports,
      dateRange: range
        ? { from: formatDayKey(range.from), to: formatDayKey(range.to) }
        : null,
      activityFrom: formatDayKey(activityRange.from),
      activityTo: formatDayKey(activityRange.to),
      activityByDay,
    };
  },
};
