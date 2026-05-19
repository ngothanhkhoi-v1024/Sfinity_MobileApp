import { apiClient } from './client';

export interface DashboardStats {
  users: number;
  admins: number;
  contents: number;
  publishedContents: number;
  draftContents: number;
  categories: number;
  feedback: number;
  pendingFeedback: number;
  pendingReports: number;
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const { data } = await apiClient.get<DashboardStats>('/admin/dashboard/stats');
  return data;
}
