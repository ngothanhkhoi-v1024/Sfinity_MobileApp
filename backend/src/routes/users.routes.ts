import { UserRole, UserStatus } from '../types/enums';
import { Router } from 'express';

import { CreateAdminDto } from '../dto/create-admin.dto';
import { UpdateUserDto } from '../dto/update-user.dto';
import { asyncHandler } from '../lib/async-handler';
import { HttpError } from '../lib/http-error';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { usersService } from '../services/users.service';
import { adminSubscriptionService } from '../services/admin-subscription.service';
import { AdminUpdateSubscriptionDto } from '../dto/admin-subscription.dto';

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
  '/:id/subscription',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(await adminSubscriptionService.getUserSubscription(req.params.id));
  }),
);

usersRouter.patch(
  '/:id/subscription',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(AdminUpdateSubscriptionDto, req.body);
    res.json(
      await adminSubscriptionService.updateUserSubscription(
        req.params.id,
        dto,
        req.user!.sub,
      ),
    );
  }),
);

usersRouter.post(
  '/:id/subscription/reset-usage',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    res.json(await adminSubscriptionService.resetUserUsage(req.params.id));
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

    if (req.user?.sub === req.params.id && dto.status === UserStatus.BANNED) {
      throw new HttpError(
        400,
        'Không thể tự chuyển tài khoản đang đăng nhập sang không hoạt động',
        'Bad Request',
      );
    }

    res.json(await usersService.update(req.params.id, dto));
  }),
);

usersRouter.delete(
  '/:id',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    if (req.user?.sub === req.params.id) {
      throw new HttpError(
        400,
        'Không thể xóa tài khoản đang đăng nhập',
        'Bad Request',
      );
    }

    res.json(await usersService.remove(req.params.id));
  }),
);
