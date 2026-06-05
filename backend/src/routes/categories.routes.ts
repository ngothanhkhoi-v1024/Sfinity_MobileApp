import { UserRole } from '../types/enums';
import { Router } from 'express';

import { CreateCategoryDto, UpdateCategoryDto } from '../dto/category.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { categoriesService } from '../services/categories.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const categoriesRouter = Router();

categoriesRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    res.json(await categoriesService.findAll());
  }),
);

categoriesRouter.get(
  '/:id',
  asyncHandler(async (req, res) => {
    res.json(await categoriesService.findOne(req.params.id));
  }),
);

categoriesRouter.post(
  '/',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateCategoryDto, req.body);
    res.json(await categoriesService.create(dto));
  }),
);

categoriesRouter.patch(
  '/:id',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdateCategoryDto, req.body);
    res.json(await categoriesService.update(req.params.id, dto));
  }),
);

categoriesRouter.delete(
  '/:id',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(await categoriesService.remove(req.params.id));
  }),
);
