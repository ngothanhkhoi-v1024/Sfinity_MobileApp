import { apiClient } from './client';

export interface DocumentItem {
  id: string;
  title: string;
  body: string;
  status: 'DRAFT' | 'PENDING' | 'PUBLISHED' | 'REJECTED' | 'HIDDEN';
  authorId: string;
  categoryId: string | null;
  type: 'document';
  fileUrl: string | null;
  fileType: string | null;
  fileSize: number | null;
  subjectCode: string | null;
  tags: string[];
  downloadsCount: number;
  likesCount: number;
  placeId: string | null;
  createdAt: string;
  updatedAt: string;
  author?: { id: string; name: string; email: string };
  category?: { id: string; name: string; slug?: string } | null;
}

export interface DocumentListResponse {
  items: DocumentItem[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export async function fetchDocuments(params?: {
  search?: string;
  status?: string;
  categoryId?: string;
  authorId?: string;
  placeId?: string;
  tags?: string;
  page?: number;
  limit?: number;
}): Promise<DocumentListResponse> {
  const { data } = await apiClient.get<DocumentListResponse>('/document', {
    params: { ...params, type: 'document' },
  });
  return data;
}

export async function createDocument(payload: {
  title: string;
  body: string;
  status?: string;
  categoryId?: string;
  fileUrl?: string;
  fileType?: string;
  fileSize?: number;
  subjectCode?: string;
  tags?: string[];
  placeId?: string;
}): Promise<DocumentItem> {
  const { data } = await apiClient.post<DocumentItem>('/document', { ...payload, type: 'document' });
  return data;
}

export async function updateDocument(
  id: string,
  payload: Partial<{
    title: string;
    body: string;
    status: string;
    categoryId: string | null;
    fileUrl: string | null;
    fileType: string | null;
    fileSize: number | null;
    subjectCode: string | null;
    tags: string[];
    placeId: string | null;
  }>,
): Promise<DocumentItem> {
  const { data } = await apiClient.patch<DocumentItem>(`/document/${id}`, payload);
  return data;
}

export async function deleteDocument(id: string): Promise<void> {
  await apiClient.delete(`/document/${id}`);
}

export async function publishDocument(id: string): Promise<DocumentItem> {
  const { data } = await apiClient.patch<DocumentItem>(`/document/${id}/publish`);
  return data;
}

export async function unpublishDocument(id: string): Promise<DocumentItem> {
  const { data } = await apiClient.patch<DocumentItem>(`/document/${id}/unpublish`);
  return data;
}

export async function adminHideDocument(id: string, reason: string): Promise<DocumentItem> {
  const { data } = await apiClient.patch<DocumentItem>(`/document/${id}/admin-hide`, { reason });
  return data;
}

export async function adminDeleteDocument(id: string, reason: string): Promise<void> {
  await apiClient.delete(`/document/${id}/admin-delete`, { data: { reason } });
}

export async function adminUnhideDocument(id: string, note?: string): Promise<DocumentItem> {
  const { data } = await apiClient.patch<DocumentItem>(`/document/${id}/admin-unhide`, { note });
  return data;
}

export async function adminApproveDocument(id: string, note?: string): Promise<DocumentItem> {
  const { data } = await apiClient.patch<DocumentItem>(`/document/${id}/approve`, { note });
  return data;
}

export async function adminRejectDocument(id: string, reason: string): Promise<DocumentItem> {
  const { data } = await apiClient.patch<DocumentItem>(`/document/${id}/reject`, { reason });
  return data;
}
