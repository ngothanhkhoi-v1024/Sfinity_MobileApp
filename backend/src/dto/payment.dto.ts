import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateMomoPaymentDto {
  @IsString()
  @IsIn(['pro'])
  planId!: 'pro';

  @IsString()
  @IsIn(['monthly', 'yearly'])
  cycle!: 'monthly' | 'yearly';

  /**
   * MoMo payment method. Nếu bỏ trống → dùng `payWithMethod` (đa năng: QR +
   * trang chọn method). Mobile dùng để hiển thị QR trong app thay vì mở app MoMo.
   */
  @IsOptional()
  @IsIn(['captureWallet', 'payWithMethod', 'payWithATM', 'payWithCC'])
  method?: 'captureWallet' | 'payWithMethod' | 'payWithATM' | 'payWithCC';
}

/** IPN do MoMo gửi tới — không validate chặt vì MoMo tự ký HMAC. */
export class MomoIpnDto {
  @IsString()
  @MinLength(1)
  partnerCode!: string;

  @IsString()
  @MinLength(1)
  orderId!: string;

  @IsString()
  @MinLength(1)
  requestId!: string;

  @IsString()
  amount!: string;

  @IsString()
  orderInfo!: string;

  @IsString()
  orderType!: string;

  @IsString()
  transId!: string;

  @IsString()
  resultCode!: string;

  @IsString()
  message!: string;

  @IsString()
  payType!: string;

  @IsString()
  responseTime!: string;

  @IsString()
  extraData!: string;

  @IsString()
  signature!: string;
}
