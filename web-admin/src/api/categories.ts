import { apiClient } from './client';

export type CategoryType = 'DOCUMENT' | 'PLACE';

export interface CategoryItem {
  id: string;
  name: string;
  slug?: string;
  description?: string | null;
  type?: CategoryType;
  _count?: { documents?: number };
}

export async function fetchCategories(type?: CategoryType): Promise<CategoryItem[]> {
  const params = type ? { type } : undefined;
  const { data } = await apiClient.get<CategoryItem[]>('/categories', { params });
  return data;
}

export async function createCategory(payload: {
  name: string;
  slug?: string;
  description?: string;
  type?: CategoryType;
}): Promise<CategoryItem> {
  const { data } = await apiClient.post<CategoryItem>('/categories', payload);
  return data;
}

export async function updateCategory(
  id: string,
  payload: Partial<{ name: string; slug?: string; description: string }>,
): Promise<CategoryItem> {
  const { data } = await apiClient.patch<CategoryItem>(`/categories/${id}`, payload);
  return data;
}

export async function deleteCategory(id: string): Promise<void> {
  await apiClient.delete(`/categories/${id}`);
}

// Tiện ích địa điểm — endpoint riêng, không phụ thuộc Firestore
export interface AmenityItem {
  id: string;
  name: string;
  slug?: string;
  description?: string;
  type: 'PLACE';
}

export async function fetchAmenities(): Promise<AmenityItem[]> {
  const { data } = await apiClient.get<AmenityItem[]>('/amenities');
  return data;
}

export async function createAmenity(payload: Omit<AmenityItem, 'type' | 'slug'>): Promise<AmenityItem> {
  const { data } = await apiClient.post<AmenityItem>('/amenities', payload);
  return data;
}

export async function updateAmenity(
  id: string,
  payload: Partial<{ name: string; slug?: string; description: string }>,
): Promise<AmenityItem> {
  const { data } = await apiClient.patch<AmenityItem>(`/amenities/${id}`, payload);
  return data;
}

export async function deleteAmenity(id: string): Promise<void> {
  await apiClient.delete(`/amenities/${id}`);
}
