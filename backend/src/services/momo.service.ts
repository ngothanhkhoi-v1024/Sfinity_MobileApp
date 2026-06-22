import { config } from '../lib/config';
import {
  createMomoPayment,
  isMomoResultSuccess,
  newMomoOrderId,
  verifySignature,
} from '../lib/momo';
import { HttpError } from '../lib/http-error';
import { planSettingsService } from './plan-settings.service';
import { subscriptionService } from './subscription.service';

export type PlanId = 'pro';
export type BillingCycle = 'monthly' | 'yearly';

export interface CreatePaymentInput {
  userId: string;
  planId: PlanId;
  cycle: BillingCycle;
  method?: 'captureWallet' | 'payWithMethod' | 'payWithATM' | 'payWithCC';
}

// Default requestType cho MoMo - dùng captureWallet để test
const DEFAULT_MOMO_REQUEST_TYPE = 'captureWallet' as const;

export interface CreatePaymentResult {
  orderId: string;
  requestId: string;
  amount: number;
  payUrl: string;
  deeplink?: string;
  qrCodeUrl?: string;
  expiresAt?: Date;
}

export const momoService = {
  /** Tạo payment request tới MoMo và ghi transaction PENDING vào Firestore. */
  async createPayment(input: CreatePaymentInput): Promise<CreatePaymentResult> {
    if (!config.momoPartnerCode || !config.momoAccessKey || !config.momoSecretKey) {
      throw new HttpError(
        503,
        'Cổng thanh toán MoMo chưa được cấu hình trên máy chủ',
        'Service Unavailable',
      );
    }
    if (!config.momoIpnUrl) {
      throw new HttpError(
        503,
        'MOMO_IPN_URL chưa được cấu hình — cần URL backend có thể truy cập từ internet để nhận IPN',
        'Service Unavailable',
      );
    }
    const plan = await planSettingsService.getPlan(input.planId);
    if (!plan) {
      throw new HttpError(400, 'Gói không hợp lệ hoặc đã tắt', 'Bad Request');
    }
    const amount = await planSettingsService.getPlanPrice(input.planId, input.cycle);

    const orderId = newMomoOrderId('sfvip');
    const requestId = newMomoOrderId('req');
    // Dùng orderInfo ASCII cho signature MoMo (không dấu tiếng Việt)
    const orderInfo = `Thanh toan goi ${plan.name} - ${input.cycle === 'yearly' ? '1 nam' : '1 thang'} - Sfinity`;

    await subscriptionService.createTransaction({
      orderId,
      requestId,
      userId: input.userId,
      planId: input.planId,
      cycle: input.cycle,
      amount,
      orderInfo,
    });

    const momoRes = await createMomoPayment({
      orderId,
      requestId,
      amount,
      orderInfo,
      requestType: input.method ?? DEFAULT_MOMO_REQUEST_TYPE,
    });

    if (momoRes.resultCode !== 0 || !momoRes.payUrl) {
      await subscriptionService.markTransactionFailed(orderId, {
        resultCode: momoRes.resultCode,
        message: momoRes.message || 'Không tạo được yêu cầu thanh toán MoMo',
      });
      throw new HttpError(
        502,
        momoRes.message || 'MoMo từ chối tạo thanh toán',
        'Bad Gateway',
      );
    }

    return {
      orderId: momoRes.orderId,
      requestId: momoRes.requestId,
      amount,
      payUrl: momoRes.payUrl,
      deeplink: momoRes.deeplink,
      qrCodeUrl: momoRes.qrCodeUrl,
    };
  },

  /**
   * Xử lý IPN từ MoMo: xác minh chữ ký, cập nhật transaction, gia hạn VIP.
   * Trả về `{ resultCode: 0, message }` nếu thành công — MoMo yêu cầu HTTP 200
   * với JSON `{ resultCode, message, ... }` để họ ngừng retry.
   */
  async handleIpn(body: Record<string, any>): Promise<{
    resultCode: number;
    message: string;
  }> {
    const signature = typeof body.signature === 'string' ? body.signature : '';
    const ok = verifySignature(body, signature);
    if (!ok) {
      console.warn('[MoMo IPN] Chữ ký không hợp lệ', body);
      return { resultCode: 97, message: 'Invalid signature' };
    }

    const orderId = String(body.orderId ?? '');
    const resultCode = Number(body.resultCode ?? -1);
    if (!orderId) {
      return { resultCode: 98, message: 'Missing orderId' };
    }

    const tx = await subscriptionService.getTransaction(orderId);
    if (!tx) {
      console.warn('[MoMo IPN] Không tìm thấy giao dịch', { orderId });
      return { resultCode: 99, message: 'Order not found' };
    }

    if (tx.status === 'SUCCESS') {
      return { resultCode: 0, message: 'Already processed' };
    }

    if (isMomoResultSuccess(resultCode)) {
      await subscriptionService.markTransactionSuccess(orderId, {
        resultCode,
        message: typeof body.message === 'string' ? body.message : undefined,
        transId: body.transId !== undefined ? Number(body.transId) : undefined,
        payType: typeof body.payType === 'string' ? body.payType : undefined,
        responseTime:
          body.responseTime !== undefined
            ? Number(body.responseTime)
            : undefined,
      });
      return { resultCode: 0, message: 'Success' };
    }

    await subscriptionService.markTransactionFailed(orderId, {
      resultCode,
      message: typeof body.message === 'string' ? body.message : undefined,
    });
    return { resultCode: 0, message: 'Recorded as failed' };
  },
};
