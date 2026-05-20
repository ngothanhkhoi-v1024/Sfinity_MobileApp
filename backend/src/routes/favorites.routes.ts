import { Router } from 'express';

import { asyncHandler } from '../lib/async-handler';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { favoritesService } from '../services/favorites.service';

export const favoritesRouter = Router();

favoritesRouter.use(jwtAuthMiddleware);

favoritesRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    res.json(await favoritesService.findByUser(req.user!.sub));
  }),
);

favoritesRouter.post(
  '/:contentId',
  asyncHandler(async (req, res) => {
    res.json(
      await favoritesService.add(req.user!.sub, req.params.contentId),
    );
  }),
);

favoritesRouter.delete(
  '/:contentId',
  asyncHandler(async (req, res) => {
    res.json(
      await favoritesService.remove(req.user!.sub, req.params.contentId),
    );
  }),
);
