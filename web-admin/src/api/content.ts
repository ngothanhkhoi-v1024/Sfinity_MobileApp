import { apiClient } from './client';

export interface ContentItem {
  id: string;
  title: string;
  body: string;
  status: 'DRAFT' | 'PUBLISHED';
  authorId: string;
  categoryId?: string | null;
  createdAt: string;
  updatedAt: string;
  author?: { id: string; name: string; email: string };
  category?: { id: string; name: string; slug?: string } | null;
}

export interface ContentListResponse {
  items: ContentItem[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export async function fetchContent(params?: {
  search?: string;
  status?: string;
  page?: number;
}): Promise<ContentListResponse> {
  const { data } = await apiClient.get<ContentListResponse>('/content', { params });
  return data;
}

export async function createContent(payload: {
  title: string;
  body: string;
  status?: string;
  categoryId?: string;
}): Promise<ContentItem> {
  const { data } = await apiClient.post<ContentItem>('/content', payload);
  return data;
}

export async function updateContent(
  id: string,
  payload: Partial<{ title: string; body: string; status: string; categoryId: string | null }>,
): Promise<ContentItem> {
  const { data } = await apiClient.patch<ContentItem>(`/content/${id}`, payload);
  return data;
}

export async function deleteContent(id: string): Promise<void> {
  await apiClient.delete(`/content/${id}`);
}

export async function publishContent(id: string): Promise<ContentItem> {
  const { data } = await apiClient.patch<ContentItem>(`/content/${id}/publish`);
  return data;
}

export async function unpublishContent(id: string): Promise<ContentItem> {
  const { data } = await apiClient.patch<ContentItem>(`/content/${id}/unpublish`);
  return data;
}
