import { IsEmail, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @IsEmail({}, { message: 'Nhập email hợp lệ.' })
  email!: string;

  @IsString({ message: 'Mật khẩu phải là chuỗi ký tự.' })
  @MinLength(6, { message: 'Mật khẩu tối thiểu 6 ký tự.' })
  password!: string;
}

export class RegisterDto {
  @IsEmail({}, { message: 'Nhập email hợp lệ.' })
  email!: string;

  @IsString({ message: 'Mật khẩu phải là chuỗi ký tự.' })
  @MinLength(6, { message: 'Mật khẩu tối thiểu 6 ký tự.' })
  password!: string;

  @IsString({ message: 'Họ tên phải là chuỗi ký tự.' })
  @MinLength(2, { message: 'Nhập họ tên (tối thiểu 2 ký tự).' })
  name!: string;
}
