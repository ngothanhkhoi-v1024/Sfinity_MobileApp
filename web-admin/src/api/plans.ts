import { apiClient } from './client';

export interface PlanConfig {
  id: string;
  name: string;
  nameVi: string;
  monthlyPrice: number;
  yearlyPrice: number;
  enabled: boolean;
}

export interface FreeLimitsConfig {
  documentDownloads: number;
  placesCreated: number;
  friends: number;
  canCreateGroup: boolean;
}

export interface PlanSettings {
  plans: Record<string, PlanConfig>;
  freeLimits: FreeLimitsConfig;
  updatedAt?: string;
}

export async function fetchPlanSettings(): Promise<PlanSettings> {
  const { data } = await apiClient.get<PlanSettings>('/admin/plans');
  return data;
}

export async function updatePlanSettings(patch: {
  plans?: Record<string, Partial<PlanConfig>>;
  freeLimits?: Partial<FreeLimitsConfig>;
}): Promise<PlanSettings> {
  const { data } = await apiClient.patch<PlanSettings>('/admin/plans', patch);
  return data;
}
