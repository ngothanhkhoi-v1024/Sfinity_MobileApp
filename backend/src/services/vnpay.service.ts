import { config } from '../lib/config';
import {
  buildVnpayPaymentUrl,
  createVnpaySignature,
  formatVnpayAmount,
  formatVnpayDate,
  isVnpaySuccess,
  newVnpayTxnRef,
  parseVnpayReturnParams,
  verifyVnpaySignature,
} from '../lib/vnpay';
import { HttpError } from '../lib/http-error';
import { subscriptionService } from './subscription.service';
import { planSettingsService } from './plan-settings.service';

export type PaymentMethod = 'vnpay';

export interface CreateVnpayPaymentInput {
  userId: string;
  planId: 'pro';
  cycle: 'monthly' | 'yearly';
  bankCode?: string;
}

export interface CreateVnpayPaymentResult {
  orderId: string;
  paymentUrl: string;
  amount: number;
  orderInfo: string;
  expiresAt?: Date;
}

export const vnpayService = {
  /**
   * Tạo payment request tới VNPay và ghi transaction PENDING vào Firestore.
   */
  async createPayment(input: CreateVnpayPaymentInput): Promise<CreateVnpayPaymentResult> {
    if (!config.vnpayTmnCode || !config.vnpayHashSecret) {
      throw new HttpError(
        503,
        'Cổng thanh toán VNPay chưa được cấu hình trên máy chủ',
        'Service Unavailable',
      );
    }

    const plan = await planSettingsService.getPlan(input.planId);
    if (!plan) {
      throw new HttpError(400, 'Gói không hợp lệ hoặc đã tắt', 'Bad Request');
    }

    const amount = await planSettingsService.getPlanPrice(input.planId, input.cycle);
    const orderId = newVnpayTxnRef('sfvip');
    const now = new Date();
    const expireDate = new Date(now.getTime() + 15 * 60 * 1000); // 15 minutes expiry

    const orderInfo = `Thanh toan goi ${plan.name} - ${input.cycle === 'yearly' ? '1 nam' : '1 thang'} - Sfinity`;

    await subscriptionService.createTransaction({
      orderId,
      requestId: orderId,
      userId: input.userId,
      planId: input.planId,
      cycle: input.cycle,
      amount,
      orderInfo,
    });

    // Chỉ thêm bankCode nếu có giá trị - VNPay bỏ qua các trường rỗng
    const paymentParams: Record<string, string> = {
      vnp_Version: '2.1.0',
      vnp_Command: 'pay',
      vnp_TmnCode: config.vnpayTmnCode,
      vnp_Amount: String(formatVnpayAmount(amount)),
      vnp_CurrCode: 'VND',
      vnp_Locale: 'vn',
      vnp_TxnRef: orderId,
      vnp_OrderInfo: orderInfo,
      vnp_OrderType: 'billpayment',
      vnp_ReturnUrl: config.vnpayReturnUrl,
      vnp_CreateDate: formatVnpayDate(now),
      vnp_ExpireDate: formatVnpayDate(expireDate),
      vnp_IpAddr: '127.0.0.1',
    };

    // Chỉ thêm bankCode nếu có giá trị
    if (input.bankCode && input.bankCode.length > 0) {
      paymentParams.vnp_BankCode = input.bankCode;
    }

    console.log('[VNPay] Payment params for signature:', JSON.stringify(paymentParams, null, 2));

    const paymentUrl = buildVnpayPaymentUrl(paymentParams as any);

    console.log('[VNPay] Created payment:', {
      orderId,
      amount,
      paymentUrl: paymentUrl.substring(0, 100) + '...',
    });

    return {
      orderId,
      paymentUrl,
      amount,
      orderInfo,
      expiresAt: expireDate,
    };
  },

  /**
   * Xử lý return URL từ VNPay (sau khi user thanh toán xong).
   */
  async handleReturn(queryString: string): Promise<{
    success: boolean;
    orderId: string;
    amount: number;
    message: string;
  }> {
    console.log('[VNPay Return] Raw query string:', queryString);
    const params = parseVnpayReturnParams(queryString);
    console.log('[VNPay Return] Parsed params:', JSON.stringify(params, null, 2));
    console.log('[VNPay Return] Config returnUrl:', config.vnpayReturnUrl);
    console.log('[VNPay Return] Config hashSecret:', config.vnpayHashSecret ? '***' + config.vnpayHashSecret.substring(config.vnpayHashSecret.length - 4) : 'NOT SET');

    const {
      vnp_ResponseCode,
      vnp_TransactionStatus,
      vnp_TxnRef,
      vnp_Amount,
      vnp_OrderInfo,
    } = params;

    const receivedHash = params.vnp_SecureHash || '';
    console.log('[VNPay Return] Received hash:', receivedHash);

    // Xóa vnp_SecureHash và vnp_SecureHashType trước khi verify
    const { vnp_SecureHash: _, vnp_SecureHashType: __, ...paramsForSign } = params;

    // Tính lại hash để debug
    const expectedHash = createVnpaySignature(paramsForSign as Record<string, string | number>);
    console.log('[VNPay Return] Expected hash:', expectedHash);

    if (!verifyVnpaySignature(params, receivedHash)) {
      console.warn('[VNPay Return] Invalid signature');
      throw new HttpError(400, 'Chữ ký không hợp lệ', 'Bad Request');
    }

    const orderId = vnp_TxnRef || '';
    const tx = await subscriptionService.getTransaction(orderId);

    if (!tx) {
      throw new HttpError(404, 'Không tìm thấy giao dịch', 'Not Found');
    }

    const success = isVnpaySuccess(vnp_ResponseCode || '') && vnp_TransactionStatus === '00';

    if (success) {
      await subscriptionService.markTransactionSuccess(orderId, {
        resultCode: Number(vnp_ResponseCode),
        message: 'Thanh toán VNPay thành công',
        transId: params.vnp_TransactionNo ? Number(params.vnp_TransactionNo) : undefined,
        payType: params.vnp_CardType,
      });
    }

    return {
      success,
      orderId,
      amount: tx.amount,
      message: success ? 'Thanh toán thành công' : `Thanh toán thất bại: ${vnp_ResponseCode}`,
    };
  },

  /**
   * Xử lý IPN từ VNPay (server-to-server).
   */
  async handleIpn(queryString: string): Promise<{
    RspCode: string;
    Message: string;
  }> {
    const params = parseVnpayReturnParams(queryString);

    const { vnp_ResponseCode, vnp_TransactionStatus, vnp_TxnRef } = params;

    const signature = params.vnp_SecureHash || '';
    if (!verifyVnpaySignature(params, signature)) {
      console.warn('[VNPay IPN] Invalid signature', params);
      return { RspCode: '97', Message: 'Invalid signature' };
    }

    const orderId = vnp_TxnRef || '';
    if (!orderId) {
      return { RspCode: '98', Message: 'Missing orderId' };
    }

    const tx = await subscriptionService.getTransaction(orderId);
    if (!tx) {
      console.warn('[VNPay IPN] Transaction not found:', orderId);
      return { RspCode: '99', Message: 'Order not found' };
    }

    if (tx.status === 'SUCCESS') {
      return { RspCode: '00', Message: 'Already processed' };
    }

    const success = isVnpaySuccess(vnp_ResponseCode || '') && vnp_TransactionStatus === '00';

    if (success) {
      await subscriptionService.markTransactionSuccess(orderId, {
        resultCode: Number(vnp_ResponseCode),
        message: 'Thanh toán VNPay thành công qua IPN',
        transId: params.vnp_TransactionNo ? Number(params.vnp_TransactionNo) : undefined,
        payType: params.vnp_CardType,
      });
      return { RspCode: '00', Message: 'Confirm Success' };
    }

    await subscriptionService.markTransactionFailed(orderId, {
      resultCode: Number(vnp_ResponseCode),
      message: `Thanh toán thất bại: ${vnp_ResponseCode}`,
    });

    return { RspCode: '00', Message: 'Recorded as failed' };
  },
};
