import { apiClient } from './client';

export interface NotificationItem {
  id: string;
  title: string;
  body: string;
  read: boolean;
  createdAt: string;
  user?: { id: string; name: string; email: string };
}

export async function fetchNotificationHistory(): Promise<NotificationItem[]> {
  const { data } = await apiClient.get<NotificationItem[]>('/notifications/admin/history');
  return data;
}

export async function sendNotification(payload: {
  title: string;
  body: string;
  userId?: string;
}): Promise<unknown> {
  const { data } = await apiClient.post('/notifications/admin/send', payload);
  return data;
}
