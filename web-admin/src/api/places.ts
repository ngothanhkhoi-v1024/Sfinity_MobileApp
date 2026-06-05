import { apiClient } from './client';

export type PlaceVisibility = 'PRIVATE' | 'PUBLIC';
export type PlaceModerationStatus = 'NONE' | 'PENDING' | 'APPROVED' | 'REJECTED' | 'HIDDEN';

export interface PlaceItem {
  id: string;
  title: string;
  body: string;
  /** @deprecated use visibility + moderationStatus */
  status?: string;
  visibility: PlaceVisibility;
  moderationStatus: PlaceModerationStatus;
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
  category?: { id: string; name: string; slug?: string } | null;
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

export function getPlaceModerationStatus(place: PlaceItem): PlaceModerationStatus {
  if (place.moderationStatus) return place.moderationStatus;
  const s = (place.status ?? '').toUpperCase();
  if (s === 'PENDING') return 'PENDING';
  if (s === 'REJECTED') return 'REJECTED';
  if (s === 'HIDDEN') return 'HIDDEN';
  if (s === 'PUBLISHED') return 'APPROVED';
  return 'NONE';
}

export function getPlaceVisibility(place: PlaceItem): PlaceVisibility {
  if (place.visibility) return place.visibility;
  const s = (place.status ?? '').toUpperCase();
  if (s === 'DRAFT') return 'PRIVATE';
  return 'PUBLIC';
}

export async function fetchPlaces(params?: {
  search?: string;
  visibility?: string;
  moderationStatus?: string;
  categoryId?: string;
  authorId?: string;
  zone?: string;
  page?: number;
  limit?: number;
}): Promise<PlaceListResponse> {
  const { data } = await apiClient.get<PlaceListResponse>('/places', {
    params,
  });
  return data;
}

export async function createPlace(payload: {
  title: string;
  body: string;
  visibility?: string;
  moderationStatus?: string;
  categoryId?: string;
  latitude?: number | null;
  longitude?: number | null;
  address?: string;
  zone?: string;
  tags?: string[];
}): Promise<PlaceItem> {
  const { data } = await apiClient.post<PlaceItem>('/places', payload);
  return data;
}

export async function updatePlace(
  id: string,
  payload: Partial<{
    title: string;
    body: string;
    visibility: string;
    moderationStatus: string;
    categoryId: string | null;
    latitude: number | null;
    longitude: number | null;
    address: string | null;
    zone: string | null;
    tags: string[];
  }>,
): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/places/${id}`, payload);
  return data;
}

export async function deletePlace(id: string): Promise<void> {
  await apiClient.delete(`/places/${id}`);
}

export async function publishPlace(id: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/places/${id}/publish`);
  return data;
}

export async function unpublishPlace(id: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/places/${id}/unpublish`);
  return data;
}

export async function adminHidePlace(id: string, reason: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/places/${id}/admin-hide`, { reason });
  return data;
}

export async function adminDeletePlace(id: string, reason: string): Promise<void> {
  await apiClient.delete(`/places/${id}/admin-delete`, { data: { reason } });
}

export async function adminUnhidePlace(id: string, note?: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/places/${id}/admin-unhide`, { note });
  return data;
}

export async function adminApprovePlace(id: string, note?: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/places/${id}/approve`, { note });
  return data;
}

export async function adminRejectPlace(id: string, reason: string): Promise<PlaceItem> {
  const { data } = await apiClient.patch<PlaceItem>(`/places/${id}/reject`, { reason });
  return data;
}
