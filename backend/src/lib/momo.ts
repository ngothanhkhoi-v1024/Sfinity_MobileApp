import { createHmac } from 'crypto';

import { config } from './config';

/**
 * Tham khảo tài liệu MoMo v2:
 *   https://developers.momo.vn/v2/docs/payment/api/wallet/onetime/
 *
 * MoMo dùng chữ ký HMAC-SHA256 với secret key.
 * Raw signature string = nối các cặp `key=value` bằng `&`, **sắp xếp khóa
 * theo thứ tự alphabet**.
 */
export function buildRawSignature(params: Record<string, string>): string {
  return Object.keys(params)
    .sort()
    .map((key) => `${key}=${params[key]}`)
    .join('&');
}

export function signWithSecret(rawSignature: string): string {
  return createHmac('sha256', config.momoSecretKey).update(rawSignature).digest('hex');
}

export function verifySignature(
  params: Record<string, string | number | undefined>,
  signature: string,
): boolean {
  const filtered: Record<string, string> = {};
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null) continue;
    filtered[key] = String(value);
  }
  delete filtered.signature;
  const expected = signWithSecret(buildRawSignature(filtered));
  // So sánh an toàn, tránh timing attack cơ bản
  if (expected.length !== signature.length) return false;
  let mismatch = 0;
  for (let i = 0; i < expected.length; i++) {
    mismatch |= expected.charCodeAt(i) ^ signature.charCodeAt(i);
  }
  return mismatch === 0;
}

export interface CreateMomoPaymentInput {
  orderId: string;
  requestId: string;
  amount: number;
  orderInfo: string;
  extraData?: string;
  lang?: 'vi' | 'en';
  /**
   * MoMo requestType quyết định trải nghiệm thanh toán.
   * - `captureWallet`: mở app MoMo qua deeplink (mặc định cũ, có deeplink).
   * - `payWithMethod`: trang MoMo cho phép chọn QR ATM / thẻ / MoMo → có `qrCodeUrl`.
   * - `payWithATM`: chỉ QR ATM nội địa → có `qrCodeUrl`.
   * - `payWithCC`: chỉ QR thẻ quốc tế → có `qrCodeUrl`.
   */
  requestType?: 'captureWallet' | 'payWithMethod' | 'payWithATM' | 'payWithCC';
}

export interface CreateMomoPaymentResult {
  payUrl: string;
  deeplink?: string;
  qrCodeUrl?: string;
  resultCode: number;
  message: string;
  orderId: string;
  requestId: string;
  signature: string;
}

/**
 * Gọi MoMo `/v2/gateway/api/create` để tạo yêu cầu thanh toán.
 * Trả về response thô từ MoMo (chưa xác minh chữ ký phía server — IPN sẽ xác
 * minh bằng `verifySignature` ở bước sau).
 */
export async function createMomoPayment(
  input: CreateMomoPaymentInput,
): Promise<CreateMomoPaymentResult> {
  const lang = input.lang ?? 'vi';
  const extraData = input.extraData ?? '';

  const signatureParams: Record<string, string> = {
    accessKey: config.momoAccessKey,
    amount: String(input.amount),
    extraData,
    ipnUrl: config.momoIpnUrl,
    orderId: input.orderId,
    orderInfo: input.orderInfo,
    partnerCode: config.momoPartnerCode,
    redirectUrl: config.momoRedirectUrl,
    requestId: input.requestId,
    requestType: input.requestType ?? 'captureWallet', // Dùng captureWallet như code C# mẫu
  };

  // Debug: Log config values to verify they're loaded correctly
  console.log('[MoMo Config] partnerCode:', config.momoPartnerCode);
  console.log('[MoMo Config] accessKey:', config.momoAccessKey);
  console.log('[MoMo Config] secretKey length:', config.momoSecretKey.length);

  const signature = signWithSecret(buildRawSignature(signatureParams));

  // MoMo v2 yêu cầu amount là số nguyên trong JSON body, KHÔNG phải string
  const body = {
    ...signatureParams,
    amount: input.amount, // Gửi số nguyên, không phải string
    lang,
    signature,
  };

  // Debug: Log request to MoMo
  console.log('[MoMo] Request body:', JSON.stringify(body, null, 2));
  console.log('[MoMo] Raw signature string:', buildRawSignature(signatureParams));

  const url = `${config.momoBaseUrl.replace(/\/+$/, '')}/v2/gateway/api/create`;

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(
      `MoMo create payment HTTP ${res.status}: ${text || res.statusText}`,
    );
  }

  const data = (await res.json()) as Record<string, unknown>;

  // Debug: Log response from MoMo
  console.log('[MoMo] Response:', JSON.stringify(data, null, 2));

  return {
    payUrl: typeof data.payUrl === 'string' ? data.payUrl : '',
    deeplink: typeof data.deeplink === 'string' ? data.deeplink : undefined,
    qrCodeUrl: typeof data.qrCodeUrl === 'string' ? data.qrCodeUrl : undefined,
    resultCode: typeof data.resultCode === 'number' ? data.resultCode : -1,
    message: typeof data.message === 'string' ? data.message : '',
    orderId: typeof data.orderId === 'string' ? data.orderId : input.orderId,
    requestId:
      typeof data.requestId === 'string' ? data.requestId : input.requestId,
    signature: typeof data.signature === 'string' ? data.signature : '',
  };
}

/** MoMo coi resultCode === 0 là giao dịch thành công. */
export function isMomoResultSuccess(resultCode: number): boolean {
  return resultCode === 0;
}

/** Tạo orderId/requestId duy nhất, an toàn để gọi MoMo nhiều lần. */
export function newMomoOrderId(prefix = 'sf'): string {
  const ts = Date.now();
  const rand = Math.random().toString(36).slice(2, 8);
  return `${prefix}_${ts}_${rand}`;
}
