import 'dotenv/config';

export const config = {
  port: Number(process.env.PORT ?? 3000),
  jwtSecret: process.env.JWT_SECRET ?? 'dev-secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID,
  firebaseClientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  firebasePrivateKey: process.env.FIREBASE_PRIVATE_KEY,
  apiBaseUrl: process.env.API_BASE_URL ?? 'http://localhost:3000',
  smtpHost: process.env.SMTP_HOST,
  smtpPort: Number(process.env.SMTP_PORT ?? 587),
  smtpSecure: process.env.SMTP_SECURE === 'true',
  smtpUser: process.env.SMTP_USER,
  smtpPass: process.env.SMTP_PASS,
  smtpFrom: process.env.SMTP_FROM ?? 'Sfinity <no-reply@sfinity.com>',
  openaiApiKey: process.env.OPENAI_API_KEY,
  openaiModel: process.env.OPENAI_MODEL ?? 'gpt-4o-mini',
  geminiApiKey: process.env.GEMINI_API_KEY, // Reload triggered v2
  momoEnv: process.env.MOMO_ENV ?? 'sandbox',
  momoPartnerCode: process.env.MOMO_PARTNER_CODE ?? '',
  momoAccessKey: process.env.MOMO_ACCESS_KEY ?? '',
  momoSecretKey: process.env.MOMO_SECRET_KEY ?? '',
  momoBaseUrl:
    process.env.MOMO_BASE_URL ??
    (process.env.MOMO_ENV === 'production'
      ? 'https://payment.momo.vn'
      : 'https://test-payment.momo.vn'),
  momoRedirectUrl: process.env.MOMO_REDIRECT_URL ?? 'sfinity://payment-callback',
  momoIpnUrl: process.env.MOMO_IPN_URL ?? '',
} as const;
