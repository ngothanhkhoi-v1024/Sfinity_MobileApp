import type { UserRole } from '@prisma/client';
import type { NextFunction, Request, Response } from 'express';

import { HttpError } from '../lib/http-error';

export function rolesMiddleware(...roles: UserRole[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      next(new HttpError(401, 'Unauthorized', 'Unauthorized'));
      return;
    }
    if (!roles.includes(req.user.role)) {
      next(new HttpError(403, 'Forbidden resource', 'Forbidden'));
      return;
    }
    next();
  };
}
