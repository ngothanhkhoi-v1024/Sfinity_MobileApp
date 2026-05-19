import axios from 'axios';

import { AUTH_TOKEN_KEY, config } from '@/config';

export const apiClient = axios.create({
  baseURL: `${config.apiBaseUrl}/api`,
  timeout: 30_000,
  headers: {
    'Content-Type': 'application/json',
  },
});

apiClient.interceptors.request.use((requestConfig) => {
  const token = localStorage.getItem(AUTH_TOKEN_KEY);
  if (token) {
    requestConfig.headers.Authorization = `Bearer ${token}`;
  }
  return requestConfig;
});

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem(AUTH_TOKEN_KEY);
      if (!window.location.pathname.startsWith('/login')) {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  },
);
