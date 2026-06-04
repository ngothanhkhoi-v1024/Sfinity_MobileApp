import { apiClient } from './client';

export interface PlaceItem {
  id: string;
  title: string;
  body: string;
  status: 'DRAFT' | 'PENDING' | 'PUBLISHED' | 'REJECTED' | 'HIDDEN';
  authorId: string;
  categoryId: string | null;
  type: 'place';
  latitude: number | null;
  longitude: number | null;
  address: string | null;
  zone: string | null;
  tags: string[];
  createdAt: string;
  updatedAt: string;
  author?: { id: string; name: string; email: string };
  category?: { id: string; name: string; slug: string } | null;
}

export interface PlaceListResponse {
  items: PlaceItem[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export const PLACE_ZONES = [
  { id: 'khu_a', label: 'Khu A' },
  { id: 'khu_b', label: 'Khu B' },
  { id: 'library', label: 'Thư viện' },
  { id: 'dorm', label: 'Ký túc xá' },
  { id: 'cafeteria', label: 'Căng tin' },
  { id: 'sports', label: 'Sân thể thao' },
  { id: 'faculty_it', label: 'Khoa CNTT' },
  { id: 'faculty_biz', label: 'Khoa Kinh tế' },
  { id: 'other', label: 'Khác' },
] as const;

export async function fetchPlaces(params?: {
  search?: string;
  status?: string;
  categoryId?: string;
  authorId?: string;
  zone?: string;
  page?: number;
  limit?: number;
}): Promise<PlaceListResponse> {
  const { data } = await apiClient.get<PlaceListResponse>('/document', {
    params: { ...params, type: 'place' },
  });
  return data;
}

export async function createPlace(payload: {
  title: string;
  body: string;
  status?: string;
  categoryId?: string;
  latitude?: number | null;
  longitude?: number | null;
  address?: string;
  zone?: string;
  tags?: string[];
}): Promise<PlaceItem> {
  const { data } = await apiClient.post<PlaceItem>('/document', { ...payload, type: 'place' });
  return data;
}

export async function updatePlace(
  id: string,
  payload: Partial<{
    title: string;
    body: string;
    status: string;
    categoryId: string | null;
    latitude: number | null;
    longitude: number | null;
    address: string | null;
    zone: string | null;
    tags: string[];
  }>,
): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/document/${id}`, payload);
  return data;
}

export async function deletePlace(id: string): Promise<void> {
  await apiClient.delete(`/document/${id}`);
}

export async function publishPlace(id: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/document/${id}/publish`);
  return data;
}

export async function unpublishPlace(id: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/document/${id}/unpublish`);
  return data;
}

export async function adminHidePlace(id: string, reason: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/document/${id}/admin-hide`, { reason });
  return data;
}

export async function adminDeletePlace(id: string, reason: string): Promise<void> {
  await apiClient.delete(`/document/${id}/admin-delete`, { data: { reason } });
}

export async function adminUnhidePlace(id: string, note?: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/document/${id}/admin-unhide`, { note });
  return data;
}

export async function adminApprovePlace(id: string, note?: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/document/${id}/approve`, { note });
  return data;
}

export async function adminRejectPlace(id: string, reason: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/document/${id}/reject`, { reason });
  return data;
}
