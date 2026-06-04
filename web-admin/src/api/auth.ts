import type { AuthResponse, LoginCredentials } from '@/types/auth';
import { config } from '@/config';

import { apiClient } from './client';

const MOCK_ADMIN = {
  email: 'admin@sfinity.com',
  password: 'admin123',
};

async function mockLogin(credentials: LoginCredentials): Promise<AuthResponse> {
  await new Promise((resolve) => setTimeout(resolve, 600));

  if (
    credentials.email !== MOCK_ADMIN.email ||
    credentials.password !== MOCK_ADMIN.password
  ) {
    throw new Error('Email hoặc mật khẩu không đúng');
  }

  return {
    accessToken: 'mock-admin-token',
    user: {
      id: '1',
      email: MOCK_ADMIN.email,
      name: 'Quản trị viên',
      role: 'admin',
    },
  };
}

export async function login(credentials: LoginCredentials): Promise<AuthResponse> {
  if (config.useMockAuth) {
    return mockLogin(credentials);
  }

  const { data } = await apiClient.post<AuthResponse>('/auth/admin/login', credentials);
  return data;
}

export async function getProfile(): Promise<AuthResponse['user']> {
  if (config.useMockAuth) {
    return {
      id: '1',
      email: MOCK_ADMIN.email,
      name: 'Quản trị viên',
      role: 'admin',
    };
  }

  const { data } = await apiClient.get<AuthResponse['user']>('/auth/me');
  return data;
}

export async function forgotPassword(email: string): Promise<void> {
  await apiClient.post('/auth/forgot-password', { email });
}


export async function resetPassword(email: string, code: string, newPassword: string): Promise<void> {
  await apiClient.post('/auth/reset-password', { email, code, newPassword });
}