import type { NextFunction, Request, Response } from 'express';
import { randomUUID } from 'crypto';
import { logger } from '../lib/logger';

export function loggingMiddleware(req: Request, res: Response, next: NextFunction): void {
  const requestId = (req.headers['x-request-id'] as string) || randomUUID();
  req.id = requestId;
  res.setHeader('x-request-id', requestId);

  const startTime = process.hrtime();

  // Log request info
  logger.info({
    msg: 'Incoming Request',
    id: req.id,
    method: req.method,
    url: req.originalUrl || req.url,
    ip: req.ip,
    userAgent: req.headers['user-agent'],
    body: req.body,
    query: req.query,
  });

  // Track response
  res.on('finish', () => {
    const duration = process.hrtime(startTime);
    const durationMs = duration[0] * 1e3 + duration[1] * 1e-6;

    const logPayload = {
      msg: 'Outgoing Response',
      id: req.id,
      method: req.method,
      url: req.originalUrl || req.url,
      statusCode: res.statusCode,
      durationMs: parseFloat(durationMs.toFixed(2)),
      userId: req.user?.sub,
    };

    if (res.statusCode >= 500) {
      logger.error(logPayload);
    } else if (res.statusCode >= 400) {
      logger.warn(logPayload);
    } else {
      logger.info(logPayload);
    }
  });

  next();
}
