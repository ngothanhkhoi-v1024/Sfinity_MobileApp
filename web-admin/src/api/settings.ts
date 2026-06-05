import { apiClient } from './client';

export interface SystemSettings {
  autoApproveDocuments: boolean;
  autoApprovePlaces: boolean;
}

export async function fetchSettings(): Promise<SystemSettings> {
  const { data } = await apiClient.get<SystemSettings>('/settings');
  return data;
}

export async function updateSettings(patch: Partial<SystemSettings>): Promise<SystemSettings> {
  const { data } = await apiClient.patch<SystemSettings>('/settings', patch);
  return data;
}
