import { UserRole } from '../types/enums';
import { Router } from 'express';

import { CreateNotificationDto } from '../dto/notification.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { notificationsService } from '../services/notifications.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const notificationsRouter = Router();

notificationsRouter.get(
  '/admin/history',
  ...adminOnly,
  asyncHandler(async (_req, res) => {
    res.json(await notificationsService.findAllAdmin());
  }),
);

notificationsRouter.post(
  '/admin/send',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateNotificationDto, req.body);
    res.json(await notificationsService.create(dto));
  }),
);

notificationsRouter.get(
  '/',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(await notificationsService.findByUser(req.user!.sub));
  }),
);

notificationsRouter.patch(
  '/read-all',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(await notificationsService.markAllRead(req.user!.sub));
  }),
);

notificationsRouter.patch(
  '/:id/read',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await notificationsService.markRead(req.user!.sub, req.params.id),
    );
  }),
);

notificationsRouter.delete(
  '/',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(await notificationsService.deleteAll(req.user!.sub));
  }),
);

notificationsRouter.delete(
  '/:id',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    res.json(
      await notificationsService.delete(req.user!.sub, req.params.id),
    );
  }),
);
