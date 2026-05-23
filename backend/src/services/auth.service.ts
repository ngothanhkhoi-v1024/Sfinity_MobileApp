import { AuthProvider, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

import { config } from '../lib/config';
import { getFirebaseAuth } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { prisma } from '../lib/prisma';
import type {
  ChangePasswordDto,
  ForgotPasswordDto,
  ResetPasswordDto,
  UpdateProfileDto,
} from '../dto/password.dto';
import type { LoginDto, RegisterDto } from '../dto/login.dto';
import type { FirebaseLoginDto } from '../dto/firebase-login.dto';

function sanitizeUser(user: {
  id: string;
  email: string;
  name: string;
  avatar: string | null;
  role: UserRole;
  status: string;
  authProvider: AuthProvider;
  createdAt: Date;
}) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    avatar: user.avatar ?? undefined,
    role: user.role.toLowerCase() as 'admin' | 'user',
    status: user.status,
    authProvider: user.authProvider.toLowerCase() as 'local' | 'google' | 'facebook',
    createdAt: user.createdAt,
  };
}

function signToken(user: { id: string; email: string; role: UserRole }) {
  const accessToken = jwt.sign(
    { sub: user.id, email: user.email, role: user.role },
    config.jwtSecret,
    { expiresIn: config.jwtExpiresIn as jwt.SignOptions['expiresIn'] },
  );

  return { accessToken };
}

function mapFirebaseProvider(provider: string): AuthProvider {
  switch (provider) {
    case 'google.com':
      return AuthProvider.GOOGLE;
    case 'facebook.com':
      return AuthProvider.FACEBOOK;
    default:
      throw new HttpError(400, 'Nhà cung cấp Firebase không hợp lệ', 'Bad Request');
  }
}

export const authService = {
  async login(dto: LoginDto, adminOnly = false) {
    const user = await prisma.user.findUnique({ where: { email: dto.email } });

    if (!user) {
      throw new HttpError(401, 'Email hoặc mật khẩu không đúng', 'Unauthorized');
    }

    if (!user.passwordHash) {
      throw new HttpError(
        400,
        'Tài khoản này đang sử dụng đăng nhập Google/Facebook. Hãy đăng nhập bằng nút mạng xã hội.',
        'Bad Request',
      );
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new HttpError(401, 'Email hoặc mật khẩu không đúng', 'Unauthorized');
    }

    if (user.status === 'BANNED') {
      throw new HttpError(401, 'Tài khoản đã bị khóa', 'Unauthorized');
    }

    if (adminOnly && user.role !== UserRole.ADMIN) {
      throw new HttpError(401, 'Tài khoản không có quyền quản trị', 'Unauthorized');
    }

    return {
      ...signToken(user),
      user: sanitizeUser(user),
    };
  },

  async loginWithFirebase(dto: FirebaseLoginDto) {
    let decoded: Awaited<ReturnType<ReturnType<typeof getFirebaseAuth>['verifyIdToken']>>;

    try {
      decoded = await getFirebaseAuth().verifyIdToken(dto.idToken);
    } catch {
      throw new HttpError(401, 'Firebase token không hợp lệ', 'Unauthorized');
    }

    const tokenProvider = decoded.firebase?.sign_in_provider ?? '';

    if (tokenProvider !== dto.provider) {
      throw new HttpError(400, 'Provider không khớp với Firebase token', 'Bad Request');
    }

    const authProvider = mapFirebaseProvider(tokenProvider);
    const email = decoded.email?.trim().toLowerCase();

    if (!email) {
      throw new HttpError(400, 'Firebase token không có email', 'Bad Request');
    }

    const displayName =
      decoded.name?.trim() ||
      email.split('@')[0] ||
      'Sfinity User';

    const avatar =
      typeof decoded.picture === 'string' && decoded.picture.trim().length > 0
        ? decoded.picture
        : null;

    let user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email,
          name: displayName,
          avatar,
          role: UserRole.USER,
          authProvider,
          providerUserId: decoded.uid,
        },
      });
    } else {
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          name: user.name.trim().length > 0 ? user.name : displayName,
          avatar: user.avatar ?? avatar,
          authProvider,
          providerUserId: decoded.uid,
        },
      });
    }

    if (user.status === 'BANNED') {
      throw new HttpError(401, 'Tài khoản đã bị khóa', 'Unauthorized');
    }

    return {
      ...signToken(user),
      user: sanitizeUser(user),
    };
  },

  async register(dto: RegisterDto) {
    const exists = await prisma.user.findUnique({ where: { email: dto.email } });

    if (exists) {
      throw new HttpError(409, 'Email đã được sử dụng', 'Conflict');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await prisma.user.create({
      data: {
        email: dto.email,
        passwordHash,
        name: dto.name,
        role: UserRole.USER,
        authProvider: AuthProvider.LOCAL,
      },
    });

    return {
      ...signToken(user),
      user: sanitizeUser(user),
    };
  },

  async getProfile(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      throw new HttpError(401, 'Unauthorized', 'Unauthorized');
    }

    return sanitizeUser(user);
  },

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await prisma.user.update({
      where: { id: userId },
      data: { name: dto.name, avatar: dto.avatar },
    });

    return sanitizeUser(user);
  },

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      throw new HttpError(401, 'Unauthorized', 'Unauthorized');
    }

    if (!user.passwordHash) {
      throw new HttpError(
        400,
        'Tài khoản mạng xã hội chưa thiết lập mật khẩu',
        'Bad Request',
      );
    }

    const valid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!valid) {
      throw new HttpError(401, 'Mật khẩu hiện tại không đúng', 'Unauthorized');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 10);
    await prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash,
        authProvider: AuthProvider.LOCAL,
      },
    });

    return { success: true };
  },

  generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  },

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await prisma.user.findUnique({ where: { email: dto.email } });

    if (!user) {
      throw new HttpError(404, 'Không tìm thấy tài khoản với email này', 'Not Found');
    }

    const code = authService.generateOtp();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await prisma.passwordReset.updateMany({
      where: { email: dto.email, used: false },
      data: { used: true },
    });

    await prisma.passwordReset.create({
      data: { email: dto.email, code, expiresAt },
    });

    return {
      message: 'Mã OTP đã được gửi (demo: hiển thị trực tiếp)',
      code,
      expiresInMinutes: 15,
    };
  },

  async resetPassword(dto: ResetPasswordDto) {
    const record = await prisma.passwordReset.findFirst({
      where: {
        email: dto.email,
        code: dto.code,
        used: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!record) {
      throw new HttpError(400, 'Mã OTP không hợp lệ hoặc đã hết hạn', 'Bad Request');
    }

    const user = await prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 10);

    await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: {
          passwordHash,
          authProvider: AuthProvider.LOCAL,
        },
      }),
      prisma.passwordReset.update({
        where: { id: record.id },
        data: { used: true },
      }),
    ]);

    return { success: true };
  },
};