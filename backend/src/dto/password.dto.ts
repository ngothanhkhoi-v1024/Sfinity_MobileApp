import { IsBoolean, IsEmail, IsOptional, IsString, Length, MinLength } from 'class-validator';

export class ForgotPasswordDto {
  @IsEmail({}, { message: 'Nhập email hợp lệ.' })
  email!: string;
}

export class ResetPasswordDto {
  @IsEmail({}, { message: 'Nhập email hợp lệ.' })
  email!: string;

  @IsString({ message: 'Mã OTP phải là chuỗi ký tự.' })
  @Length(6, 6, { message: 'Mã OTP phải gồm 6 chữ số.' })
  code!: string;

  @IsString({ message: 'Mật khẩu phải là chuỗi ký tự.' })
  @MinLength(6, { message: 'Mật khẩu tối thiểu 6 ký tự.' })
  newPassword!: string;
}

export class ChangePasswordDto {
  @IsString()
  @MinLength(6)
  currentPassword!: string;

  @IsString()
  @MinLength(6)
  newPassword!: string;
}

export class UpdateProfileDto {
  @IsString()
  @MinLength(2)
  name!: string;

  @IsOptional()
  @IsString()
  avatar?: string;
}

export class UpdateNotificationPreferencesDto {
  @IsBoolean({ message: 'Trạng thái thông báo phải là boolean.' })
  notificationsEnabled!: boolean;
}

