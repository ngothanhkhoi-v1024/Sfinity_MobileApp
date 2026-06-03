import { Router } from 'express';
import { asyncHandler } from '../lib/async-handler';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { UserRole } from '../types/enums';
import { amenitiesService } from '../services/amenities.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const amenitiesRouter = Router();

amenitiesRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    console.log('[route] GET /amenities');
    const result = await amenitiesService.findAll();
    console.log('[route] returning:', result.length, 'items');
    res.json(result);
  }),
);

amenitiesRouter.get(
  '/:id',
  asyncHandler(async (req, res) => {
    res.json(await amenitiesService.findOne(req.params.id));
  }),
);

amenitiesRouter.post(
  '/',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const { name, slug, description } = req.body as {
      name: string;
      slug: string;
      description?: string;
    };
    if (!name || !slug) {
      res.status(400).json({ error: 'name và slug là bắt buộc' });
      return;
    }
    res.status(201).json(await amenitiesService.create({ name, slug, description }));
  }),
);

amenitiesRouter.patch(
  '/:id',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const { name, slug, description } = req.body as {
      name?: string;
      slug?: string;
      description?: string;
    };
    res.json(await amenitiesService.update(req.params.id, { name, slug, description }));
  }),
);

amenitiesRouter.delete(
  '/:id',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(await amenitiesService.remove(req.params.id));
  }),
);
