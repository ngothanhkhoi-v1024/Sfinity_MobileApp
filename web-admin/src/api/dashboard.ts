import { apiClient } from './client';

/** Raw stats from backend */
interface DashboardStatsRaw {
  users: number;
  admins: number;
  documents: number;
  publishedDocuments: number;
  draftDocuments: number;
  places: number;
  publishedPlaces: number;
  contents?: number;
  publishedContents?: number;
  draftContents?: number;
  categories: number;
  feedback: number;
  pendingFeedback: number;
  pendingReports: number;
  dateRange?: { from: string; to: string } | null;
  activityFrom?: string;
  activityTo?: string;
  activityByDay?: DashboardActivityDay[];
}

export interface DashboardActivityDay {
  date: string;
  users: number;
  documents: number;
  places: number;
  feedback: number;
}

export interface DashboardStats {
  users: number;
  admins: number;
  documents: number;
  places: number;
  contents: number;
  publishedContents: number;
  draftContents: number;
  categories: number;
  feedback: number;
  pendingFeedback: number;
  pendingReports: number;
  dateRange: { from: string; to: string } | null;
  activityFrom: string;
  activityTo: string;
  activityByDay: DashboardActivityDay[];
}

export interface DashboardStatsParams {
  from?: string;
  to?: string;
}

function normalizeStats(raw: DashboardStatsRaw): DashboardStats {
  const contents = raw.contents ?? raw.documents + raw.places;
  const publishedContents =
    raw.publishedContents ?? raw.publishedDocuments + raw.publishedPlaces;
  const draftContents = raw.draftContents ?? contents - publishedContents;

  return {
    users: raw.users,
    admins: raw.admins,
    documents: raw.documents,
    places: raw.places,
    contents,
    publishedContents,
    draftContents,
    categories: raw.categories,
    feedback: raw.feedback,
    pendingFeedback: raw.pendingFeedback,
    pendingReports: raw.pendingReports,
    dateRange: raw.dateRange ?? null,
    activityFrom: raw.activityFrom ?? '',
    activityTo: raw.activityTo ?? '',
    activityByDay: raw.activityByDay ?? [],
  };
}

export async function getDashboardStats(
  params?: DashboardStatsParams,
): Promise<DashboardStats> {
  const { data } = await apiClient.get<DashboardStatsRaw>('/admin/dashboard/stats', {
    params,
  });
  return normalizeStats(data);
}
