import { UserRole } from '../types/enums';
import { Router } from 'express';

import { asyncHandler } from '../lib/async-handler';
import { HttpError } from '../lib/http-error';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { dashboardService, parseDashboardDateRange } from '../services/dashboard.service';

export const dashboardRouter = Router();

dashboardRouter.get(
  '/stats',
  jwtAuthMiddleware,
  rolesMiddleware(UserRole.ADMIN),
  asyncHandler(async (req, res) => {
    const from = req.query.from as string | undefined;
    const to = req.query.to as string | undefined;

    let range;
    try {
      range = parseDashboardDateRange(from, to);
    } catch {
      throw new HttpError(400, 'Invalid date range (use from/to as YYYY-MM-DD)', 'Bad Request');
    }

    res.json(await dashboardService.getStats(range));
  }),
);
