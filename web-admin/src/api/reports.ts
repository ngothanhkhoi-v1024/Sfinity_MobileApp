import { apiClient } from './client';

export interface ReportItem {
  id: string;
  targetType: string;
  targetId?: string | null;
  reason: string;
  description?: string | null;
  status: 'PENDING' | 'RESOLVED' | 'REJECTED';
  resolution?: string | null;
  createdAt: string;
  user?: { id: string; name: string; email: string };
  userId?: string | null;
  targetInfo?: { title?: string; name?: string; authorId?: string; email?: string } | null;
}

export async function fetchReports(status?: string): Promise<ReportItem[]> {
  const { data } = await apiClient.get<ReportItem[]>('/reports', {
    params: status ? { status } : undefined,
  });
  return data;
}

export async function resolveReport(
  id: string,
  payload: { status: string; resolution?: string },
): Promise<ReportItem> {
  const { data } = await apiClient.patch<ReportItem>(`/reports/${id}/resolve`, payload);
  return data;
}

export async function updateReportDescription(
  id: string,
  description: string,
): Promise<ReportItem> {
  const { data } = await apiClient.patch<ReportItem>(`/reports/${id}`, { description });
  return data;
}
