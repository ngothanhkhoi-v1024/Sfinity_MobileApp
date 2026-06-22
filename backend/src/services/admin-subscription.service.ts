import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import type { AdminUpdateSubscriptionDto } from '../dto/admin-subscription.dto';
import type { DashboardDateRange } from './dashboard.service';
import { subscriptionService, type BillingCycle } from './subscription.service';
import { vipLimitsService } from './vip-limits.service';
import { planSettingsService } from './plan-settings.service';

const toDate = (val: unknown): Date | undefined => {
  if (!val) return undefined;
  if (val instanceof Date) return val;
  if (typeof val === 'object' && val !== null && 'toDate' in val && typeof (val as { toDate: () => Date }).toDate === 'function') {
    return (val as { toDate: () => Date }).toDate();
  }
  const d = new Date(val as string | number);
  return Number.isNaN(d.getTime()) ? undefined : d;
};

function isVipActive(data: Record<string, unknown>): boolean {
  if (data.isVip !== true) return false;
  const expires = toDate(data.vipExpiresAt);
  if (!expires) return true;
  return expires.getTime() > Date.now();
}

function formatDayKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function isInRange(date: Date, range?: DashboardDateRange): boolean {
  if (!range) return true;
  const t = date.getTime();
  return t >= range.from.getTime() && t <= range.to.getTime();
}

export const adminSubscriptionService = {
  async getUserSubscription(userId: string) {
    const doc = await getDb().collection('users').doc(userId).get();
    if (!doc.exists) {
      throw new HttpError(404, 'Không tìm thấy người dùng', 'Not Found');
    }
    const data = doc.data() as Record<string, unknown>;
    const limits = await vipLimitsService.getStatus(userId);
    const vipStatus = await subscriptionService.getUserVipStatus(userId);

    const txSnap = await getDb()
      .collection('payment_transactions')
      .where('userId', '==', userId)
      .get();

    type TxRow = Record<string, unknown> & { id: string };
    const transactions = txSnap.docs
      .map((d): TxRow => ({ id: d.id, ...(d.data() as Record<string, unknown>) }))
      .sort((a, b) => (toDate(b.createdAt)?.getTime() ?? 0) - (toDate(a.createdAt)?.getTime() ?? 0))
      .slice(0, 20)
      .map((tx) => ({
        orderId: (tx.orderId as string) ?? tx.id,
        planId: tx.planId,
        cycle: tx.cycle,
        amount: tx.amount,
        status: tx.status,
        createdAt: toDate(tx.createdAt),
        paidAt: toDate(tx.paidAt),
      }));

    return {
      userId,
      isVip: vipStatus.isVip,
      isVipFlag: data.isVip === true,
      planId: vipStatus.planId ?? (data.vipPlanId as string | undefined),
      cycle: vipStatus.cycle ?? (data.vipCycle as BillingCycle | undefined),
      expiresAt: vipStatus.expiresAt ?? toDate(data.vipExpiresAt),
      source: (data.vipSource as string | undefined) ?? vipStatus.source,
      limits,
      transactions,
    };
  },

  async updateUserSubscription(
    userId: string,
    dto: AdminUpdateSubscriptionDto,
    adminId: string,
  ) {
    const userRef = getDb().collection('users').doc(userId);
    const snap = await userRef.get();
    if (!snap.exists) {
      throw new HttpError(404, 'Không tìm thấy người dùng', 'Not Found');
    }
    const data = snap.data() as Record<string, unknown>;
    const now = new Date();

    if (dto.action === 'revoke') {
      await userRef.update({
        isVip: false,
        vipRevokedAt: now,
        vipRevokedBy: adminId,
        vipRevokeNote: dto.note ?? null,
        updatedAt: now,
      });
      return adminSubscriptionService.getUserSubscription(userId);
    }

    const planId = dto.planId ?? 'pro';
    const cycle = (dto.cycle ?? 'monthly') as BillingCycle;

    let newExpires: Date;
    if (dto.expiresAt) {
      newExpires = new Date(dto.expiresAt);
      if (Number.isNaN(newExpires.getTime())) {
        throw new HttpError(400, 'Ngày hết hạn không hợp lệ', 'Bad Request');
      }
    } else if (dto.days) {
      const currentExpires = toDate(data.vipExpiresAt);
      const base =
        currentExpires && currentExpires.getTime() > now.getTime() ? currentExpires : now;
      newExpires = new Date(base.getTime() + dto.days * 24 * 60 * 60 * 1000);
    } else if (dto.action === 'extend') {
      const currentExpires = toDate(data.vipExpiresAt);
      newExpires = subscriptionService.computeVipExpiresAt(currentExpires, cycle, now);
    } else {
      newExpires = subscriptionService.computeVipExpiresAt(undefined, cycle, now);
    }

    await userRef.update({
      isVip: true,
      vipPlanId: planId,
      vipCycle: cycle,
      vipExpiresAt: newExpires,
      vipSource: 'admin',
      vipGrantedBy: adminId,
      vipGrantNote: dto.note ?? null,
      vipGrantedAt: now,
      updatedAt: now,
    });

    return adminSubscriptionService.getUserSubscription(userId);
  },

  async resetUserUsage(userId: string) {
    const userRef = getDb().collection('users').doc(userId);
    const snap = await userRef.get();
    if (!snap.exists) {
      throw new HttpError(404, 'Không tìm thấy người dùng', 'Not Found');
    }
    await userRef.set(
      { usage: { documentDownloads: 0, placesCreated: 0 } },
      { merge: true },
    );
    return adminSubscriptionService.getUserSubscription(userId);
  },

  async listTransactions(params: {
    status?: string;
    userId?: string;
    from?: Date;
    to?: Date;
    limit?: number;
  }) {
    const db = getDb();
    const col = db.collection('payment_transactions');
    let snap;

    if (params.userId && params.status) {
      snap = await col.where('userId', '==', params.userId).where('status', '==', params.status).get();
    } else if (params.userId) {
      snap = await col.where('userId', '==', params.userId).get();
    } else if (params.status) {
      snap = await col.where('status', '==', params.status).get();
    } else {
      snap = await col.get();
    }

    let items = snap.docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        orderId: data.orderId ?? d.id,
        userId: data.userId,
        planId: data.planId,
        cycle: data.cycle,
        amount: data.amount ?? 0,
        status: data.status,
        orderInfo: data.orderInfo,
        message: data.message,
        createdAt: toDate(data.createdAt),
        paidAt: toDate(data.paidAt),
      };
    });

    if (params.from || params.to) {
      items = items.filter((tx) => {
        const date = tx.paidAt ?? tx.createdAt;
        if (!date) return false;
        if (params.from && date.getTime() < params.from.getTime()) return false;
        if (params.to && date.getTime() > params.to.getTime()) return false;
        return true;
      });
    }

    items.sort(
      (a, b) =>
        (b.paidAt ?? b.createdAt ?? new Date(0)).getTime() -
        (a.paidAt ?? a.createdAt ?? new Date(0)).getTime(),
    );

    const limit = params.limit ?? 100;
    const sliced = items.slice(0, limit);

    const userIds = [...new Set(sliced.map((t) => t.userId).filter(Boolean))];
    const userMap = new Map<string, { name: string; email: string }>();
    await Promise.all(
      userIds.map(async (uid) => {
        const u = await db.collection('users').doc(uid).get();
        if (u.exists) {
          const d = u.data()!;
          userMap.set(uid, { name: d.name ?? 'Unknown', email: d.email ?? '' });
        }
      }),
    );

    return sliced.map((tx) => ({
      ...tx,
      userName: userMap.get(tx.userId)?.name,
      userEmail: userMap.get(tx.userId)?.email,
    }));
  },

  async getRevenueStats(range?: DashboardDateRange) {
    const snap = await getDb().collection('payment_transactions').get();
    const successTx = snap.docs
      .map((d) => d.data())
      .filter((tx) => tx.status === 'SUCCESS');

    let totalRevenue = 0;
    let transactionCount = 0;
    const byPlan: Record<string, { count: number; revenue: number }> = {};
    const byCycle: Record<string, { count: number; revenue: number }> = {};
    const byDay = new Map<string, number>();

    for (const tx of successTx) {
      const paidAt = toDate(tx.paidAt) ?? toDate(tx.createdAt);
      if (!paidAt || !isInRange(paidAt, range)) continue;

      const amount = Number(tx.amount) || 0;
      totalRevenue += amount;
      transactionCount += 1;

      const planKey = (tx.planId as string) ?? 'unknown';
      if (!byPlan[planKey]) byPlan[planKey] = { count: 0, revenue: 0 };
      byPlan[planKey].count += 1;
      byPlan[planKey].revenue += amount;

      const cycleKey = (tx.cycle as string) ?? 'unknown';
      if (!byCycle[cycleKey]) byCycle[cycleKey] = { count: 0, revenue: 0 };
      byCycle[cycleKey].count += 1;
      byCycle[cycleKey].revenue += amount;

      const dayKey = formatDayKey(paidAt);
      byDay.set(dayKey, (byDay.get(dayKey) ?? 0) + amount);
    }

    const revenueByDay = Array.from(byDay.entries())
      .map(([date, revenue]) => ({ date, revenue }))
      .sort((a, b) => a.date.localeCompare(b.date));

    const settings = await planSettingsService.get();
    const planCatalog = Object.values(settings.plans).map((plan) => ({
      id: plan.id,
      name: plan.name,
      monthlyPrice: plan.monthlyPrice,
      yearlyPrice: plan.yearlyPrice,
    }));

    return {
      totalRevenue,
      transactionCount,
      byPlan: Object.entries(byPlan).map(([planId, stats]) => ({
        planId,
        planName: settings.plans[planId]?.name ?? planId,
        ...stats,
      })),
      byCycle: Object.entries(byCycle).map(([cycle, stats]) => ({ cycle, ...stats })),
      revenueByDay,
      planCatalog,
    };
  },

  async countVipUsers(): Promise<{ active: number; expired: number; total: number }> {
    const snap = await getDb().collection('users').get();
    let active = 0;
    let expired = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.isVip !== true) continue;
      if (isVipActive(data)) active += 1;
      else expired += 1;
    }
    return { active, expired, total: active + expired };
  },
};
