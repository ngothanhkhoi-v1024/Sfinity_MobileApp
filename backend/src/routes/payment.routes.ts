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
 *
 * - Nếu header Accept: application/json  → trả JSON để app mobile gọi trực tiếp.
 * - Ngược lại → trả HTML để hiển thị kết quả và redirect về app.
 *
 * Luôn gọi handleReturn() để update transaction ngay (không chờ IPN).
 */
paymentRouter.get(
  '/vnpay/return',
  asyncHandler(async (req, res) => {
    const queryString = req.url.split('?')[1] || '';
    const acceptJson = req.headers.accept?.includes('application/json') ?? false;

    // Update transaction ngay khi user quay ve — khong cho doi IPN
    let success = false;
    let resultCode = '';
    let orderId = '';
    try {
      const result = await vnpayService.handleReturn(queryString);
      success = result.success;
      resultCode = result.success ? '00' : '99';
      orderId = result.orderId;
    } catch (err: any) {
      console.error('[VNPay Return] handleReturn error:', err.message);
      const params = new URLSearchParams(queryString);
      resultCode = params.get('vnp_ResponseCode') || '99';
      orderId = params.get('vnp_TxnRef') || '';
    }

    if (acceptJson) {
      // App goi API nay truc tiep de lay ket qua thanh toan
      return res.status(200).json({
        success,
        orderId,
        resultCode,
        message: success ? 'Thanh toan thanh cong' : `Thanh toan that bai: ${resultCode}`,
      });
    }

    // Tra ve HTML de hien thi ket qua va redirect ve app
    const deepLinkParams = new URLSearchParams({
      orderId,
      resultCode,
      message: success ? 'Thanh toan thanh cong' : `Thanh toan that bai: ${resultCode}`,
    });
    const deepLink = `sfinity://payment-vnpay-callback?${deepLinkParams.toString()}`;
    const isSuccess = success || resultCode === '00';

    const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Sfinity - Thanh Toan VNPay</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .container {
      background: white;
      border-radius: 24px;
      padding: 40px;
      max-width: 380px;
      width: 90%;
      text-align: center;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
    }
    .icon {
      width: 72px;
      height: 72px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px;
    }
    .success .icon { background: #d4edda; }
    .failed .icon { background: #f8d7da; }
    h1 { font-size: 22px; color: #333; margin-bottom: 10px; }
    p { color: #666; font-size: 15px; line-height: 1.5; margin-bottom: 24px; }
    .spinner {
      width: 48px;
      height: 48px;
      border: 4px solid #f3f3f3;
      border-top: 4px solid #667eea;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin: 0 auto 20px;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div class="container ${isSuccess ? 'success' : 'failed'}" id="content">
    <div class="spinner"></div>
    <h1>Dang xu ly...</h1>
    <p>Vui long doi trong giay lat</p>
  </div>
  <script>
    // 500ms delay de WebView co the bat URL return truoc khi redirect
    setTimeout(function() { window.location.href = '${deepLink}'; }, 500);
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
