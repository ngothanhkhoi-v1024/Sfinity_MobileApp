export const config = {
  appName: 'Sfinity Admin',
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000',
  useMockAuth: import.meta.env.VITE_USE_MOCK_AUTH === 'true',
} as const;

export const AUTH_TOKEN_KEY = 'sfinity_admin_token';
export const AUTH_USER_KEY = 'sfinity_admin_user';
