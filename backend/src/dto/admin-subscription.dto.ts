import { IsIn, IsISO8601, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class AdminUpdateSubscriptionDto {
  @IsIn(['grant', 'extend', 'revoke'])
  action!: 'grant' | 'extend' | 'revoke';

  @IsOptional()
  @IsString()
  planId?: string;

  @IsOptional()
  @IsIn(['monthly', 'yearly'])
  cycle?: 'monthly' | 'yearly';

  /** Gia hạn thêm N ngày (action extend hoặc grant). */
  @IsOptional()
  @IsInt()
  @Min(1)
  days?: number;

  /** Ngày hết hạn cố định (ISO). Ưu tiên hơn days nếu có. */
  @IsOptional()
  @IsISO8601()
  expiresAt?: string;

  @IsOptional()
  @IsString()
  note?: string;
}
