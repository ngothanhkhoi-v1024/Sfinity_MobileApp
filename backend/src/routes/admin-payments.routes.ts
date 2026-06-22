import { UserRole } from '../types/enums';
import { Router } from 'express';

import { AdminUpdateSubscriptionDto } from '../dto/admin-subscription.dto';
import { asyncHandler } from '../lib/async-handler';
import { HttpError } from '../lib/http-error';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { rolesMiddleware } from '../middleware/roles.middleware';
import { adminSubscriptionService } from '../services/admin-subscription.service';
import { parseDashboardDateRange } from '../services/dashboard.service';

const adminOnly = [jwtAuthMiddleware, rolesMiddleware(UserRole.ADMIN)] as const;

export const adminPaymentsRouter = Router();

adminPaymentsRouter.use(...adminOnly);

/** Danh sách giao dịch VIP */
adminPaymentsRouter.get(
  '/transactions',
  asyncHandler(async (req, res) => {
    const status = req.query.status as string | undefined;
    const userId = req.query.userId as string | undefined;
    const fromStr = req.query.from as string | undefined;
    const toStr = req.query.to as string | undefined;
    const limit = req.query.limit ? Number(req.query.limit) : undefined;

    let range;
    try {
      range = parseDashboardDateRange(fromStr, toStr);
    } catch {
      throw new HttpError(400, 'Invalid date range', 'Bad Request');
    }

    res.json(
      await adminSubscriptionService.listTransactions({
        status,
        userId,
        from: range?.from,
        to: range?.to,
        limit,
      }),
    );
  }),
);

/** Thống kê doanh thu từ gói VIP */
adminPaymentsRouter.get(
  '/revenue',
  asyncHandler(async (req, res) => {
    const from = req.query.from as string | undefined;
    const to = req.query.to as string | undefined;

    let range;
    try {
      range = parseDashboardDateRange(from, to);
    } catch {
      throw new HttpError(400, 'Invalid date range', 'Bad Request');
    }

    const [revenue, vipCounts] = await Promise.all([
      adminSubscriptionService.getRevenueStats(range),
      adminSubscriptionService.countVipUsers(),
    ]);

    res.json({ ...revenue, vipUsers: vipCounts });
  }),
);
