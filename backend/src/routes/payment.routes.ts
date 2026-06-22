import { Router } from 'express';

import { CreateMomoPaymentDto } from '../dto/payment.dto';
import { asyncHandler } from '../lib/async-handler';
import { HttpError } from '../lib/http-error';
import { validateBody } from '../lib/validate';
import { jwtAuthMiddleware } from '../middleware/jwt.middleware';
import { momoService } from '../services/momo.service';
import { subscriptionService } from '../services/subscription.service';

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
