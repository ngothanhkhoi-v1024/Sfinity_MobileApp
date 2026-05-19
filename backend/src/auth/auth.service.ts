import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../prisma/prisma.service';
import { LoginDto, RegisterDto } from './dto/login.dto';

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
}
