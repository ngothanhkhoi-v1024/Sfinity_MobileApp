import { Router } from 'express';

import { UpdateSettingsDto } from '../dto/settings.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { UserRole } from '../types/enums';
import { settingsService } from '../services/settings.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const settingsRouter = Router();

settingsRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    res.json(await settingsService.get());
  }),
);

settingsRouter.patch(
  '/',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdateSettingsDto, req.body);
    res.json(await settingsService.update(dto));
  }),
);
