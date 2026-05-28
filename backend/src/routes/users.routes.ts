import { UserRole } from '../types/enums';
import { Router } from 'express';

import { CreateAdminDto } from '../dto/create-admin.dto';
import { UpdateUserDto } from '../dto/update-user.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { usersService } from '../services/users.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const usersRouter = Router();

usersRouter.get(
  '/',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const search = req.query.search as string | undefined;
    res.json(await usersService.findAll(search));
  }),
);

usersRouter.post(
  '/admin',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateAdminDto, req.body);
    res.json(
      await usersService.createAdmin(dto.email, dto.password, dto.name),
    );
  }),
);

usersRouter.get(
  '/:id',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(await usersService.findOne(req.params.id));
  }),
);

usersRouter.patch(
  '/:id',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdateUserDto, req.body);
    res.json(await usersService.update(req.params.id, dto));
  }),
);

usersRouter.delete(
  '/:id',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(await usersService.remove(req.params.id));
  }),
);
