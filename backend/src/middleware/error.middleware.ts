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
  console.error(err);
  res.status(500).json({
    statusCode: 500,
    message: 'Internal server error',
    error: 'Internal Server Error',
  });
}
