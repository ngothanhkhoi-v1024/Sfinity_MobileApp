import { UserRole } from '../types/enums';
import { Router } from 'express';

import { asyncHandler } from '../lib/async-handler';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { dashboardService } from '../services/dashboard.service';

export const dashboardRouter = Router();

dashboardRouter.get(
  '/stats',
  jwtAuthMiddleware,
  rolesMiddleware(UserRole.ADMIN),
  asyncHandler(async (_req, res) => {
    res.json(await dashboardService.getStats());
  }),
);
