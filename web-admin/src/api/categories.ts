import { apiClient } from './client';

export interface CategoryItem {
  id: string;
  name: string;
  slug: string;
  description?: string | null;
  _count?: { contents: number };
}

export async function fetchCategories(): Promise<CategoryItem[]> {
  const { data } = await apiClient.get<CategoryItem[]>('/categories');
  return data;
}

export async function createCategory(payload: {
  name: string;
  slug: string;
  description?: string;
}): Promise<CategoryItem> {
  const { data } = await apiClient.post<CategoryItem>('/categories', payload);
  return data;
}

export async function updateCategory(
  id: string,
  payload: Partial<{ name: string; slug: string; description: string }>,
): Promise<CategoryItem> {
  const { data } = await apiClient.patch<CategoryItem>(`/categories/${id}`, payload);
  return data;
}

export async function deleteCategory(id: string): Promise<void> {
  await apiClient.delete(`/categories/${id}`);
}
