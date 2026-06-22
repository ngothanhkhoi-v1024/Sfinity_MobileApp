import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';

/** Trạng thái giao dịch MoMo, lưu trong collection `payment_transactions`. */
export type MomoTxStatus = 'PENDING' | 'SUCCESS' | 'FAILED' | 'CANCELED';

export type BillingCycle = 'monthly' | 'yearly';

export interface CreateMomoTransactionInput {
  orderId: string;
  requestId: string;
  userId: string;
  planId: string;
  cycle: BillingCycle;
  amount: number;
  orderInfo: string;
}

export interface MomoTransactionRecord {
  id: string;
  orderId: string;
  requestId: string;
  userId: string;
  planId: string;
  cycle: BillingCycle;
  amount: number;
  orderInfo: string;
  status: MomoTxStatus;
  resultCode?: number;
  message?: string | null;
  transId?: number;
  payType?: string;
  responseTime?: number;
  createdAt: Date;
  updatedAt: Date;
  paidAt?: Date;
}

export interface SubscriptionStatusRecord {
  isVip: boolean;
  cycle?: BillingCycle;
  planId?: string;
  expiresAt?: Date;
  source?: 'momo';
}

function toDate(val: any): Date | undefined {
  if (!val) return undefined;
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
}

const txCol = () => getDb().collection('payment_transactions');

export const subscriptionService = {
  /**
   * Tính ngày hết hạn VIP: nếu user đã có VIP còn hạn, cộng dồn; ngược lại
   * lấy từ hiện tại. Trả về Date mới.
   */
  computeVipExpiresAt(
    currentExpiresAt: Date | undefined,
    cycle: BillingCycle,
    now: Date = new Date(),
  ): Date {
    const base =
      currentExpiresAt && currentExpiresAt.getTime() > now.getTime()
        ? currentExpiresAt
        : now;
    const days = cycle === 'yearly' ? 365 : 30;
    return new Date(base.getTime() + days * 24 * 60 * 60 * 1000);
  },

  async createTransaction(
    input: CreateMomoTransactionInput,
  ): Promise<MomoTransactionRecord> {
    const ref = txCol().doc(input.orderId);
    const record: MomoTransactionRecord = {
      id: input.orderId,
      orderId: input.orderId,
      requestId: input.requestId,
      userId: input.userId,
      planId: input.planId,
      cycle: input.cycle,
      amount: input.amount,
      orderInfo: input.orderInfo,
      status: 'PENDING',
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    await ref.set(record);
    return record;
  },

  async getTransaction(
    orderId: string,
  ): Promise<MomoTransactionRecord | null> {
    const doc = await txCol().doc(orderId).get();
    if (!doc.exists) return null;
    const data = doc.data() as any;
    return {
      ...data,
      createdAt: toDate(data.createdAt) ?? new Date(),
      updatedAt: toDate(data.updatedAt) ?? new Date(),
      paidAt: toDate(data.paidAt),
      expiresAt: toDate(data.expiresAt),
    } as MomoTransactionRecord;
  },

  /**
   * Đánh dấu giao dịch thành công, đồng thời cập nhật VIP trên user doc.
   * Hàm này idempotent: nếu transaction đã SUCCESS, không ghi đè paidAt/transId
   * nhưng vẫn đảm bảo user doc đúng hạn (dùng transaction l atomic).
   */
  async markTransactionSuccess(
    orderId: string,
    info: {
      resultCode: number;
      message?: string;
      transId?: number;
      payType?: string;
      responseTime?: number;
    },
  ): Promise<MomoTransactionRecord> {
    const txRef = txCol().doc(orderId);
    const snap = await txRef.get();
    if (!snap.exists) {
      throw new HttpError(404, 'Không tìm thấy giao dịch', 'Not Found');
    }
    const data = snap.data() as any;
    const cycle = (data.cycle as BillingCycle) ?? 'monthly';
    const userId: string = data.userId;
    const planId: string = data.planId;

    const db = getDb();
    const userRef = db.collection('users').doc(userId);
    const userSnap = await userRef.get();
    const userData = userSnap.exists ? (userSnap.data() as any) : null;
    const currentExpires = toDate(userData?.vipExpiresAt);
    const now = new Date();
    const newExpires = this.computeVipExpiresAt(currentExpires, cycle, now);

    const paidAt = toDate(data.paidAt) ?? now;
    const updateTx: Record<string, unknown> = {
      status: 'SUCCESS',
      resultCode: info.resultCode,
      message: info.message ?? null,
      transId: info.transId ?? null,
      payType: info.payType ?? null,
      responseTime: info.responseTime ?? null,
      paidAt,
      updatedAt: now,
    };
    const updateUser: Record<string, unknown> = {
      isVip: true,
      vipPlanId: planId,
      vipCycle: cycle,
      vipExpiresAt: newExpires,
      vipSource: 'momo',
      updatedAt: now,
    };

    const batch = db.batch();
    batch.update(txRef, updateTx);
    batch.update(userRef, updateUser);
    await batch.commit();

    return {
      ...(data as MomoTransactionRecord),
      ...updateTx,
      ...(updateUser as any),
      createdAt: toDate(data.createdAt) ?? new Date(),
      updatedAt: now,
      paidAt,
    } as MomoTransactionRecord;
  },

  async markTransactionFailed(
    orderId: string,
    info: { resultCode: number; message?: string },
  ): Promise<MomoTransactionRecord> {
    const txRef = txCol().doc(orderId);
    const snap = await txRef.get();
    if (!snap.exists) {
      throw new HttpError(404, 'Không tìm thấy giao dịch', 'Not Found');
    }
    const data = snap.data() as any;
    const now = new Date();
    const update = {
      status: 'FAILED' as MomoTxStatus,
      resultCode: info.resultCode,
      message: info.message ?? null,
      updatedAt: now,
    };
    await txRef.update(update);
    return {
      ...(data as MomoTransactionRecord),
      ...update,
      createdAt: toDate(data.createdAt) ?? new Date(),
      updatedAt: now,
      paidAt: toDate(data.paidAt),
    };
  },

  /** Lấy trạng thái VIP hiện tại của user dựa trên user doc. */
  async getUserVipStatus(userId: string): Promise<SubscriptionStatusRecord> {
    const snap = await getDb().collection('users').doc(userId).get();
    if (!snap.exists) {
      throw new HttpError(404, 'Không tìm thấy người dùng', 'Not Found');
    }
    const data = snap.data() as any;
    const isVipFlag = data.isVip === true;
    const expiresAt = toDate(data.vipExpiresAt);
    const expired = expiresAt ? expiresAt.getTime() <= Date.now() : true;
    return {
      isVip: isVipFlag && !expired,
      cycle: data.vipCycle as BillingCycle | undefined,
      planId: data.vipPlanId as string | undefined,
      expiresAt,
      source: data.vipSource as 'momo' | undefined,
    };
  },
};
