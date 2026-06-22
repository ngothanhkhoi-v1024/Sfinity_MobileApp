import { Router } from 'express';
import { asyncHandler } from '../lib/async-handler';
import { HttpError } from '../lib/http-error';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { UserRole } from '../types/enums';
import { amenitiesService } from '../services/amenities.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const amenitiesRouter = Router();

amenitiesRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    const result = await amenitiesService.findAll();
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
    const { name, description } = req.body as {
      name: string;
      description?: string;
    };
    if (!name) {
      throw new HttpError(400, 'name là bắt buộc', 'Bad Request');
    }
    res.status(201).json(await amenitiesService.create({ name, description }));
  }),
);

amenitiesRouter.patch(
  '/:id',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const { name, description } = req.body as {
      name?: string;
      description?: string;
    };
    res.json(await amenitiesService.update(req.params.id, { name, description }));
  }),
);

amenitiesRouter.delete(
  '/:id',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(await amenitiesService.remove(req.params.id));
  }),
);
