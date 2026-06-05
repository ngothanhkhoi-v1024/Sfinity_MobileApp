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
  };
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const { data } = await apiClient.get<DashboardStatsRaw>('/admin/dashboard/stats');
  return normalizeStats(data);
}
