import { Router } from 'express';

import { UpdatePlanSettingsDto } from '../dto/plan-settings.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { UserRole } from '../types/enums';
import { planSettingsService } from '../services/plan-settings.service';

export const plansPublicRouter = Router();

/** Công khai — mobile đọc giá gói & hạn mức free (không cần auth). */
plansPublicRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    const settings = await planSettingsService.get();
    res.json({
      plans: Object.values(settings.plans).filter((p) => p.enabled),
      freeLimits: settings.freeLimits,
    });
  }),
);

export const adminPlansRouter = Router();

adminPlansRouter.use(jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN));

adminPlansRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    res.json(await planSettingsService.get());
  }),
);

adminPlansRouter.patch(
  '/',
  asyncHandler(async (req, res) => {
    const dto = await validateBody(UpdatePlanSettingsDto, req.body);
    res.json(await planSettingsService.update(dto));
  }),
);
