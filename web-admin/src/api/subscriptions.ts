import { apiClient } from './client';

export interface PaymentTransaction {
  id: string;
  orderId: string;
  userId: string;
  userName?: string;
  userEmail?: string;
  planId: string;
  cycle: string;
  amount: number;
  status: string;
  orderInfo?: string;
  message?: string | null;
  createdAt?: string;
  paidAt?: string;
}

export interface RevenueByPlan {
  planId: string;
  planName: string;
  count: number;
  revenue: number;
}

export interface RevenueByCycle {
  cycle: string;
  count: number;
  revenue: number;
}

export interface RevenueDay {
  date: string;
  revenue: number;
}

export interface RevenueStats {
  totalRevenue: number;
  transactionCount: number;
  byPlan: RevenueByPlan[];
  byCycle: RevenueByCycle[];
  revenueByDay: RevenueDay[];
  vipUsers: { active: number; expired: number; total: number };
  planCatalog?: { id: string; name: string; monthlyPrice: number; yearlyPrice: number }[];
}

export interface UserSubscriptionDetail {
  userId: string;
  isVip: boolean;
  isVipFlag: boolean;
  planId?: string;
  cycle?: string;
  expiresAt?: string;
  source?: string;
  limits: {
    isVip: boolean;
    documentDownloads: { used: number; limit: number | null; remaining: number | null };
    placesCreated: { used: number; limit: number | null; remaining: number | null };
    friends: { used: number; limit: number | null; remaining: number | null };
    canCreateGroup: boolean;
  };
  transactions: PaymentTransaction[];
}

export interface UpdateSubscriptionPayload {
  action: 'grant' | 'extend' | 'revoke';
  planId?: string;
  cycle?: 'monthly' | 'yearly';
  days?: number;
  expiresAt?: string;
  note?: string;
}

export async function fetchTransactions(params?: {
  status?: string;
  userId?: string;
  from?: string;
  to?: string;
  limit?: number;
}): Promise<PaymentTransaction[]> {
  const { data } = await apiClient.get<PaymentTransaction[]>('/admin/payments/transactions', {
    params,
  });
  return data;
}

export async function fetchRevenueStats(params?: {
  from?: string;
  to?: string;
}): Promise<RevenueStats> {
  const { data } = await apiClient.get<RevenueStats>('/admin/payments/revenue', { params });
  return data;
}

export async function fetchUserSubscription(userId: string): Promise<UserSubscriptionDetail> {
  const { data } = await apiClient.get<UserSubscriptionDetail>(`/users/${userId}/subscription`);
  return data;
}

export async function updateUserSubscription(
  userId: string,
  payload: UpdateSubscriptionPayload,
): Promise<UserSubscriptionDetail> {
  const { data } = await apiClient.patch<UserSubscriptionDetail>(
    `/users/${userId}/subscription`,
    payload,
  );
  return data;
}

export async function resetUserUsage(userId: string): Promise<UserSubscriptionDetail> {
  const { data } = await apiClient.post<UserSubscriptionDetail>(
    `/users/${userId}/subscription/reset-usage`,
    {},
  );
  return data;
}

export function formatVnd(amount: number): string {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
}
