import { ReportStatus, UserRole } from '../types/enums';
import { Router } from 'express';

import { CreateReportDto, ResolveReportDto } from '../dto/report.dto';
import { asyncHandler } from '../lib/async-handler';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { reportsService } from '../services/reports.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const reportsRouter = Router();

reportsRouter.post(
  '/',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateReportDto, req.body);
    res.json(await reportsService.create(req.user!.sub, dto));
  }),
);

reportsRouter.get(
  '/',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const status = req.query.status as ReportStatus | undefined;
    res.json(await reportsService.findAll(status));
  }),
);

reportsRouter.patch(
  '/:id/resolve',
  ...adminOnly,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(ResolveReportDto, req.body);
    res.json(await reportsService.resolve(req.params.id, dto));
  }),
);
