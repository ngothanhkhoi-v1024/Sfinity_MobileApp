import type { UserRole } from './enums';

declare global {
  namespace Express {
    interface User {
      sub: string;
      email: string;
      role: UserRole;
    }
    interface Request {
      user?: User;
    }
  }
}

export {};
