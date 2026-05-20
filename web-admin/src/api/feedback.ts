import { apiClient } from './client';

export interface FeedbackItem {
  id: string;
  message: string;
  rating?: number | null;
  resolved: boolean;
  reply?: string | null;
  createdAt: string;
  user?: { id: string; name: string; email: string };
}

export async function fetchFeedback(resolved?: boolean): Promise<FeedbackItem[]> {
  const { data } = await apiClient.get<FeedbackItem[]>('/feedback', {
    params: resolved !== undefined ? { resolved: String(resolved) } : undefined,
  });
  return data;
}

export async function replyFeedback(id: string, reply: string): Promise<FeedbackItem> {
  const { data } = await apiClient.patch<FeedbackItem>(`/feedback/${id}/reply`, { reply });
  return data;
}
