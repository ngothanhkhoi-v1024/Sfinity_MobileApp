import { apiClient } from './client';

export interface UserRecord {
  id: string;
  email: string;
  name: string;
  role: string;
  status: string;
  createdAt: string;
  updatedAt: string;
}

export async function fetchUsers(search?: string): Promise<UserRecord[]> {
  const { data } = await apiClient.get<UserRecord[]>('/users', {
    params: search ? { search } : undefined,
  });
  return data;
}

export async function updateUser(
  id: string,
  payload: Partial<{ name: string; role: string; status: string }>,
): Promise<UserRecord> {
  const { data } = await apiClient.patch<UserRecord>(`/users/${id}`, payload);
  return data;
}

export async function deleteUser(id: string): Promise<void> {
  await apiClient.delete(`/users/${id}`);
}
