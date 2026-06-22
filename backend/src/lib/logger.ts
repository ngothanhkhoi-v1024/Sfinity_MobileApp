import pino from 'pino';
import { config } from './config';

const isDev = config.nodeEnv === 'development';

export const logger = pino({
  level: config.logLevel,
  redact: {
    paths: [
      'req.headers.authorization',
      '*.password',
      '*.token',
      '*.accessToken',
      '*.refreshToken',
      '*.apiKey',
      '*.client_secret',
      'body.password',
      'body.token',
      'body.accessToken',
      'body.refreshToken',
      'body.apiKey'
    ],
    censor: '[REDACTED]',
  },
  transport: isDev
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:yyyy-mm-dd HH:MM:ss.l',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
});
