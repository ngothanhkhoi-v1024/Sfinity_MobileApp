import type { NextFunction, Request, Response } from 'express';

import { HttpError } from '../lib/http-error';

export function errorMiddleware(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof HttpError) {
    res.status(err.statusCode).json(err.payload);
    return;
  }
  // Handle Multer errors (file too large, wrong mime type, etc.)
  const multerErr = err as { code?: string; message?: string };
  if (multerErr.code === 'LIMIT_FILE_SIZE') {
    res.status(413).json({ message: 'File quá lớn. Tối đa 5MB.' });
    return;
  }
  if (multerErr.code === 'LIMIT_UNEXPECTED_FILE') {
    res.status(400).json({ message: 'File không hợp lệ.' });
    return;
  }
  console.error(err);
  res.status(500).json({
    statusCode: 500,
    message: 'Internal server error',
    error: 'Internal Server Error',
  });
}
