import { Router } from 'express';

import { asyncHandler } from '../lib/async-handler';
import { optionalJwtAuthMiddleware } from '../middleware/jwt.middleware';
import { exploreService } from '../services/explore.service';

export const exploreRouter = Router();

exploreRouter.get(
  '/featured',
  asyncHandler(async (_req, res) => {
    res.json(await exploreService.getFeatured());
  }),
);

exploreRouter.get(
  '/weekly-stats',
  optionalJwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    if (!req.user?.sub) {
      const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      res.json({
        weekStart: new Date().toISOString(),
        totalPlaces: 0,
        totalDownloads: 0,
        days: labels.map((label) => ({ label, places: 0, downloads: 0 })),
      });
      return;
    }
    res.json(await exploreService.getWeeklyStats(req.user.sub));
  }),
);

exploreRouter.get(
  '/top-users',
  asyncHandler(async (_req, res) => {
    res.json(await exploreService.getTopUsers());
  }),
);
