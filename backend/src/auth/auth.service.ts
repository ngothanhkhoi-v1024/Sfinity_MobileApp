import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../prisma/prisma.service';
import { LoginDto, RegisterDto } from './dto/login.dto';
import {
  ChangePasswordDto,
  ForgotPasswordDto,
  ResetPasswordDto,
  UpdateProfileDto,
} from './dto/password.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
  ) {}

  private sanitizeUser(user: {
    id: string;
    email: string;
    name: string;
    avatar: string | null;
    role: UserRole;
    status: string;
    createdAt: Date;
  }) {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      avatar: user.avatar ?? undefined,
      role: user.role.toLowerCase() as 'admin' | 'user',
      status: user.status,
      createdAt: user.createdAt,
    };
  }

  private signToken(user: { id: string; email: string; role: UserRole }) {
    const accessToken = this.jwt.sign({
      sub: user.id,
      email: user.email,
      role: user.role,
    });
    return { accessToken };
  }

  async login(dto: LoginDto, adminOnly = false) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) throw new UnauthorizedException('Email hoặc mật khẩu không đúng');

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Email hoặc mật khẩu không đúng');

    if (user.status === 'BANNED') {
      throw new UnauthorizedException('Tài khoản đã bị khóa');
    }

    if (adminOnly && user.role !== UserRole.ADMIN) {
      throw new UnauthorizedException('Tài khoản không có quyền quản trị');
    }

    return {
      ...this.signToken(user),
      user: this.sanitizeUser(user),
    };
  }

  async register(dto: RegisterDto) {
    const exists = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (exists) throw new ConflictException('Email đã được sử dụng');

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash,
        name: dto.name,
        role: UserRole.USER,
      },
    });

    return {
      ...this.signToken(user),
      user: this.sanitizeUser(user),
    };
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException();
    return this.sanitizeUser(user);
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { name: dto.name, avatar: dto.avatar },
    });
    return this.sanitizeUser(user);
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException();

    const valid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Mật khẩu hiện tại không đúng');

    const passwordHash = await bcrypt.hash(dto.newPassword, 10);
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
    return { success: true };
  }

  private generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) {
      throw new NotFoundException('Không tìm thấy tài khoản với email này');
    }

    const code = this.generateOtp();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await this.prisma.passwordReset.updateMany({
      where: { email: dto.email, used: false },
      data: { used: true },
    });

    await this.prisma.passwordReset.create({
      data: { email: dto.email, code, expiresAt },
    });

    return {
      message: 'Mã OTP đã được gửi (demo: hiển thị trực tiếp)',
      code,
      expiresInMinutes: 15,
    };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const record = await this.prisma.passwordReset.findFirst({
      where: {
        email: dto.email,
        code: dto.code,
        used: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!record) {
      throw new BadRequestException('Mã OTP không hợp lệ hoặc đã hết hạn');
    }

    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) throw new NotFoundException();

    const passwordHash = await bcrypt.hash(dto.newPassword, 10);
    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: user.id }, data: { passwordHash } }),
      this.prisma.passwordReset.update({ where: { id: record.id }, data: { used: true } }),
    ]);

    return { success: true };
  }
}
