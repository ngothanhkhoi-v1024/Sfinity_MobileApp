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
 * Redirect thẳng về app qua deep link sfinity://
 */
paymentRouter.get(
  '/vnpay/return',
  asyncHandler(async (req, res) => {
    const queryString = req.url.split('?')[1] || '';
    const params = new URLSearchParams(queryString);

    const vnp_ResponseCode = params.get('vnp_ResponseCode') || '';
    const vnp_TxnRef = params.get('vnp_TxnRef') || '';
    const vnp_TransactionStatus = params.get('vnp_TransactionStatus') || '';
    const vnp_Amount = params.get('vnp_Amount') || '';

    const deepLinkParams = new URLSearchParams({
      orderId: vnp_TxnRef,
      resultCode: vnp_ResponseCode,
      message: vnp_ResponseCode === '00' && vnp_TransactionStatus === '00'
        ? 'Thanh toan thanh cong'
        : `Thanh toan that bai: ${vnp_ResponseCode}`,
    });

    const deepLink = `sfinity://payment-vnpay-callback?${deepLinkParams.toString()}`;

    const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Sfinity - Thanh Toan VNPay</title>
  <style>
    body { font-family: -apple-system, sans-serif; display:flex; align-items:center; justify-content:center; height:100vh; margin:0; background:#f5f5f5; }
    .msg { background:white; padding:32px; border-radius:16px; text-align:center; box-shadow:0 4px 24px rgba(0,0,0,.1); }
    .msg h2 { margin:0 0 8px; color:#333; }
    .msg p { margin:0; color:#666; font-size:14px; }
  </style>
</head>
<body>
  <div class="msg">
    <h2>${vnp_ResponseCode === '00' && vnp_TransactionStatus === '00' ? 'Thanh toan thanh cong!' : 'Da nhan ket qua thanh toan'}</h2>
    <p>Dang chuyen ve ung dung...</p>
  </div>
  <script>
    // WebView will intercept sfinity:// scheme and pass back to app.
    window.location.href = '${deepLink}';
  </script>
</body>
</html>`;

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(html);
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
