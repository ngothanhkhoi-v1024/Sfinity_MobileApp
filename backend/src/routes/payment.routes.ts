import { Router } from 'express';

import { CreateMomoPaymentDto } from '../dto/payment.dto';
import { asyncHandler } from '../lib/async-handler';
import { config } from '../lib/config';
import { HttpError } from '../lib/http-error';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { momoService } from '../services/momo.service';
import { subscriptionService } from '../services/subscription.service';
import { vnpayService } from '../services/vnpay.service';

export const paymentRouter = Router();

/**
 * POST /api/payments/momo/create
 * Tạo yêu cầu thanh toán MoMo cho gói VIP. Trả về payUrl + deeplink để app
 * mở bằng url_launcher. User phải đăng nhập (JWT).
 */
paymentRouter.post(
  '/momo/create',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateMomoPaymentDto, req.body);
    const result = await momoService.createPayment({
      userId: req.user!.sub,
      planId: dto.planId,
      cycle: dto.cycle,
      method: dto.method,
    });
    res.json({
      orderId: result.orderId,
      requestId: result.requestId,
      amount: result.amount,
      payUrl: result.payUrl,
      deeplink: result.deeplink,
      qrCodeUrl: result.qrCodeUrl,
    });
  }),
);

/**
 * POST /api/payments/momo/ipn
 * MoMo server-to-server gọi endpoint này để xác nhận kết quả thanh toán.
 * Bắt buộc trả về HTTP 200 với JSON `{ resultCode, message }` để MoMo ngừng
 * retry. Không yêu cầu JWT (gọi server-to-server, xác thực bằng signature).
 */
paymentRouter.post(
  '/momo/ipn',
  asyncHandler(async (req, res) => {
    const result = await momoService.handleIpn(req.body ?? {});
    res.status(200).json(result);
  }),
);

/**
 * GET /api/payments/momo/status/:orderId
 * App gọi sau khi deep link trở về từ MoMo để xác nhận giao dịch đã được IPN
 * xử lý chưa.
 */
paymentRouter.get(
  '/momo/status/:orderId',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const orderId = req.params.orderId;
    const tx = await subscriptionService.getTransaction(orderId);
    if (!tx) {
      throw new HttpError(404, 'Không tìm thấy giao dịch', 'Not Found');
    }
    if (tx.userId !== req.user!.sub) {
      throw new HttpError(403, 'Forbidden', 'Forbidden');
    }
    res.json({
      orderId: tx.orderId,
      status: tx.status,
      resultCode: tx.resultCode,
      amount: tx.amount,
      planId: tx.planId,
      cycle: tx.cycle,
      paidAt: tx.paidAt,
    });
  }),
);

/**
 * GET /api/payments/subscription/me
 * Trả về trạng thái VIP hiện tại của user (server là source of truth).
 */
paymentRouter.get(
  '/subscription/me',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const status = await subscriptionService.getUserVipStatus(req.user!.sub);
    res.json(status);
  }),
);

/**
 * POST /api/payments/vnpay/create
 * Tạo yêu cầu thanh toán VNPay cho gói VIP. Trả về paymentUrl để mở browser.
 * User phải đăng nhập (JWT).
 */
paymentRouter.post(
  '/vnpay/create',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const dto = await validateBody(CreateMomoPaymentDto, req.body);
    const result = await vnpayService.createPayment({
      userId: req.user!.sub,
      planId: dto.planId,
      cycle: dto.cycle,
      bankCode: dto.method as string | undefined,
    });
    res.json({
      orderId: result.orderId,
      paymentUrl: result.paymentUrl,
      amount: result.amount,
      orderInfo: result.orderInfo,
      expiresAt: result.expiresAt,
    });
  }),
);

/**
 * GET /api/payments/vnpay/return
 * VNPay redirect user về URL này sau khi thanh toán.
 * Không yêu cầu JWT - xác thực bằng signature.
 */
paymentRouter.get(
  '/vnpay/return',
  asyncHandler(async (req, res) => {
    const queryString = req.url.split('?')[1] || '';
    const result = await vnpayService.handleReturn(queryString);
    // Redirect về app với kết quả
    const redirectUrl = `${config.vnpayReturnUrl}?success=${result.success}&orderId=${result.orderId}&message=${encodeURIComponent(result.message)}`;
    res.redirect(redirectUrl);
  }),
);

/**
 * POST /api/payments/vnpay/ipn
 * VNPay server-to-server gọi endpoint này để xác nhận kết quả thanh toán.
 * Bắt buộc trả về JSON `{ RspCode, Message }`.
 */
paymentRouter.post(
  '/vnpay/ipn',
  asyncHandler(async (req, res) => {
    // VNPay gửi IPN qua query string hoặc body
    let queryString = '';
    if (Object.keys(req.body || {}).length > 0) {
      queryString = new URLSearchParams(req.body).toString();
    } else if (req.query && Object.keys(req.query).length > 0) {
      queryString = new URLSearchParams(
        Object.entries(req.query).map(([k, v]) => [k, String(v)])
      ).toString();
    }
    const result = await vnpayService.handleIpn(queryString);
    res.status(200).json(result);
  }),
);

/**
 * GET /api/payments/vnpay/status/:orderId
 * App gọi để kiểm tra trạng thái giao dịch VNPay.
 */
paymentRouter.get(
  '/vnpay/status/:orderId',
  jwtAuthMiddleware,
  asyncHandler(async (req, res) => {
    const orderId = req.params.orderId;
    const tx = await subscriptionService.getTransaction(orderId);
    if (!tx) {
      throw new HttpError(404, 'Không tìm thấy giao dịch', 'Not Found');
    }
    if (tx.userId !== req.user!.sub) {
      throw new HttpError(403, 'Forbidden', 'Forbidden');
    }
    res.json({
      orderId: tx.orderId,
      status: tx.status,
      resultCode: tx.resultCode,
      amount: tx.amount,
      planId: tx.planId,
      cycle: tx.cycle,
      paidAt: tx.paidAt,
    });
  }),
);
