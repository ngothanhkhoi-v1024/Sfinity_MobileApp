import type { NextFunction, Request, Response } from 'express';

import { HttpError } from '../lib/http-error';
import { logger } from '../lib/logger';

export function errorMiddleware(
  err: unknown,
  req: Request,
  res: Response,
  _next: NextFunction,
): void {
  const reqId = req.id;

  if (err instanceof HttpError) {
    logger.warn({
      msg: 'HTTP error handled',
      id: reqId,
      statusCode: err.statusCode,
      payload: err.payload,
    });
    res.status(err.statusCode).json(err.payload);
    return;
  }

  // Handle Multer errors (file too large, wrong mime type, etc.)
  const multerErr = err as { code?: string; message?: string };
  if (multerErr.code === 'LIMIT_FILE_SIZE') {
    logger.warn({
      msg: 'Multer error handled',
      id: reqId,
      code: multerErr.code,
      message: multerErr.message,
    });
    res.status(413).json({ message: 'File quá lớn. Tối đa 5MB.' });
    return;
  }
  if (multerErr.code === 'LIMIT_UNEXPECTED_FILE') {
    logger.warn({
      msg: 'Multer error handled',
      id: reqId,
      code: multerErr.code,
      message: multerErr.message,
    });
    res.status(400).json({ message: 'File không hợp lệ.' });
    return;
  }

  logger.error({
    msg: 'Unhandled Exception',
    id: reqId,
    err: err instanceof Error ? { message: err.message, stack: err.stack } : err,
    method: req.method,
    url: req.originalUrl || req.url,
  });

  res.status(500).json({
    statusCode: 500,
    message: 'Internal server error',
    error: 'Internal Server Error',
  });
}
