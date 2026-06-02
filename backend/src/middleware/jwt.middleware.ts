import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

import { config } from '../lib/config';
import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { UserStatus } from '../types/enums';

export async function jwtAuthMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      throw new HttpError(401, 'Unauthorized', 'Unauthorized');
    }
    const token = header.slice(7);
    const decoded = jwt.verify(token, config.jwtSecret) as {
      sub: string;
      email?: string;
      role?: string;
    };
    
    const doc = await getDb().collection('users').doc(decoded.sub).get();
    if (!doc.exists) {
      throw new HttpError(401, 'Unauthorized', 'Unauthorized');
    }
    
    const user = doc.data() as any;
    if (user.status === UserStatus.BANNED) {
      throw new HttpError(401, 'Unauthorized', 'Unauthorized');
    }
    
    req.user = {
      sub: doc.id,
      email: user.email,
      role: user.role,
    };
    next();
  } catch (e) {
    if (e instanceof HttpError) {
      next(e);
      return;
    }
    next(new HttpError(401, 'Unauthorized', 'Unauthorized'));
  }
}

/** Sets [req.user] when Bearer token is valid; continues as guest otherwise. */
export async function optionalJwtAuthMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction,
): Promise<void> {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    next();
    return;
  }
  try {
    const token = header.slice(7);
    const decoded = jwt.verify(token, config.jwtSecret) as {
      sub: string;
      email?: string;
      role?: string;
    };

    const doc = await getDb().collection('users').doc(decoded.sub).get();
    if (!doc.exists) {
      next();
      return;
    }

    const user = doc.data() as { status?: string; email?: string; role?: string };
    if (user.status === UserStatus.BANNED) {
      next();
      return;
    }

    req.user = {
      sub: doc.id,
      email: user.email ?? '',
      role: (user.role ?? 'USER') as import('../types/enums').UserRole,
    };
    next();
  } catch {
    next();
  }
}
