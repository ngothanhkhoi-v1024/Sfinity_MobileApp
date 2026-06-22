import { createHmac } from 'crypto';
import { config } from './config';

/**
 * VNPay Payment Gateway Utilities
 *
 * Tài liệu: https://sandbox.vnpayment.vn/apis/docs/huong-dan-tich-hop/
 */

export interface VnpayPaymentParams {
  vnp_Version: '2.1.0';
  vnp_Command: 'pay';
  vnp_TmnCode: string;
  vnp_Amount: number; // Amount in VND (multiply by 100)
  vnp_CurrCode: 'VND';
  vnp_Locale: 'vn' | 'en';
  vnp_BankCode?: string;
  vnp_TxnRef: string;
  vnp_OrderInfo: string;
  vnp_OrderType: string;
  vnp_ReturnUrl: string;
  vnp_CreateDate: string; // Format: yyyyMMddHHmmss
  vnp_ExpireDate?: string; // Format: yyyyMMddHHmmss
  vnp_IpAddr: string;
  vnp_SecureHash?: string;
}

export interface VnpayReturnParams {
  vnp_Amount: string;
  vnp_BankCode: string;
  vnp_BankTrnNo: string;
  vnp_CardType: string;
  vnp_DateInfo: string;
  vnp_OrderInfo: string;
  vnp_PayDate: string;
  vnp_ResponseCode: string;
  vnp_TmnCode: string;
  vnp_TransactionNo: string;
  vnp_TransactionStatus: string;
  vnp_TxnRef: string;
  vnp_SecureHash: string;
}

/**
 * URL encode theo chuẩn VNPay (tương đương WebUtility.UrlEncode trong C#)
 */
function vnpayUrlEncode(value: string): string {
  return encodeURIComponent(value)
    .replace(/%20/g, '+')
    .replace(/!/g, '%21')
    .replace(/'/g, '%27')
    .replace(/\(/g, '%28')
    .replace(/\)/g, '%29')
    .replace(/\*/g, '%2A');
}

/**
 * Sắp xếp keys theo alphabet và tạo query string cho VNPay signature.
 * Sử dụng URL encoding theo chuẩn VNPay (thứ tự so sánh en-US Ordinal).
 */
function buildSignatureString(params: Record<string, string | number | undefined>): string {
  // Sort theo chuẩn en-US Ordinal (tương tự CompareInfo.GetCompareInfo("en-US"))
  const sortedKeys = Object.keys(params).sort((a, b) => {
    const compare = (s1: string, s2: string): number => {
      const len1 = s1.length;
      const len2 = s2.length;
      const minLen = Math.min(len1, len2);
      for (let i = 0; i < minLen; i++) {
        const c1 = s1.charCodeAt(i);
        const c2 = s2.charCodeAt(i);
        if (c1 !== c2) return c1 - c2;
      }
      return len1 - len2;
    };
    return compare(a, b);
  });

  const queryParts: string[] = [];

  for (const key of sortedKeys) {
    const value = params[key];
    // VNPay yêu cầu bỏ qua các trường có giá trị rỗng hoặc undefined
    if (value !== undefined && value !== null && value !== '') {
      queryParts.push(`${vnpayUrlEncode(key)}=${vnpayUrlEncode(String(value))}`);
    }
  }

  return queryParts.join('&');
}

/**
 * Tạo HMAC-SHA512 signature cho VNPay
 */
export function createVnpaySignature(params: Record<string, string | number>): string {
  const signatureString = buildSignatureString(params);
  console.log('[VNPay Signature] Raw string:', signatureString);
  console.log('[VNPay Signature] Hash secret:', config.vnpayHashSecret ? '***' + config.vnpayHashSecret.slice(-4) : 'NOT SET');
  const hmac = createHmac('sha512', config.vnpayHashSecret);
  hmac.update(signatureString);
  return hmac.digest('hex').toUpperCase();
}

/**
 * Xác minh VNPay return URL signature
 */
export function verifyVnpaySignature(
  params: Record<string, string | number>,
  receivedHash: string,
): boolean {
  // Loại bỏ vnp_SecureHash và vnp_SecureHashType khỏi params
  const { vnp_SecureHash, vnp_SecureHashType, ...paramsForSign } = params;
  const expectedHash = createVnpaySignature(paramsForSign as Record<string, string | number>);

  console.log('[VNPay Verify] Expected hash:', expectedHash);
  console.log('[VNPay Verify] Received hash:', receivedHash.toUpperCase());

  return expectedHash === receivedHash.toUpperCase();
}

/**
 * Format số tiền VNPay (nhân 100)
 * VNPay yêu cầu amount * 100 và là số nguyên
 */
export function formatVnpayAmount(amount: number): number {
  return Math.round(amount) * 100;
}

/**
 * Format date thành VNPay format (yyyyMMddHHmmss)
 */
export function formatVnpayDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  return `${year}${month}${day}${hours}${minutes}${seconds}`;
}

/**
 * Tạo transaction reference ID cho VNPay
 */
export function newVnpayTxnRef(prefix = 'sf'): string {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  return `${prefix}_${timestamp}_${random}`;
}

/**
 * Build VNPay payment URL
 */
export function buildVnpayPaymentUrl(params: Record<string, string>): string {
  // Tạo signature từ params (không bao gồm vnp_SecureHash)
  const paramsForSign: Record<string, string> = {};
  for (const [key, value] of Object.entries(params)) {
    if (key !== 'vnp_SecureHash' && value !== undefined && value !== null && value !== '') {
      paramsForSign[key] = String(value);
    }
  }

  const signature = createVnpaySignature(paramsForSign);

  // Build URL với tất cả params + signature (URL encoded)
  const allParams = { ...paramsForSign, vnp_SecureHash: signature };
  const queryString = buildSignatureString(allParams);
  const baseUrl = config.vnpayUrl.split('?')[0];

  console.log('[VNPay Payment URL] Query:', queryString);

  return `${baseUrl}?${queryString}`;
}

/**
 * Kiểm tra VNPay response có thành công không
 */
export function isVnpaySuccess(responseCode: string): boolean {
  return responseCode === '00';
}

/**
 * Parse VNPay return URL params (from query string).
 * Giải mã các giá trị query string đúng chuẩn để signature generator mã hóa lại chính xác (tránh double URL-encoding).
 */
export function parseVnpayReturnParams(queryString: string): Record<string, string> {
  const params: Record<string, string> = {};
  if (!queryString) return params;

  const pairs = queryString.split('&');

  for (const pair of pairs) {
    const eqIndex = pair.indexOf('=');
    if (eqIndex > 0) {
      const key = decodeURIComponent(pair.substring(0, eqIndex));
      // Giải mã dấu '+' thành khoảng trắng trước khi dùng decodeURIComponent
      const rawValue = pair.substring(eqIndex + 1);
      const value = decodeURIComponent(rawValue.replace(/\+/g, '%20'));
      params[key] = value;
    } else if (pair) {
      params[decodeURIComponent(pair)] = '';
    }
  }

  return params;
}
