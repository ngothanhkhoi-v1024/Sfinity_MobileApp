import * as bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

import { config } from '../lib/config';
import { getDb, getFirebaseAuth } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { AuthProvider, UserRole, UserStatus } from '../types/enums';
import { mailService } from './mail.service';
import type {
  ChangePasswordDto,
  ForgotPasswordDto,
  ResetPasswordDto,
  UpdateNotificationPreferencesDto,
  UpdateProfileDto,
} from '../dto/password.dto';
import type { LoginDto, RegisterDto } from '../dto/login.dto';
import type { FirebaseLoginDto } from '../dto/firebase-login.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

function sanitizeUser(user: {
  id: string;
  email: string;
  name: string;
  avatar: string | null;
  role: UserRole;
  status: string;
  authProvider: AuthProvider;
  createdAt: any;
  notificationsEnabled?: boolean;
  birthDate?: string;
  gender?: string;
  address?: string;
}) {
  return {
    id: user.id,
    email: user.email ?? '',
    name: user.name ?? '',
    avatar: user.avatar ?? undefined,
    role: (user.role ?? UserRole.USER).toLowerCase() as 'admin' | 'user',
    status: user.status ?? UserStatus.ACTIVE,
    authProvider: (user.authProvider ?? AuthProvider.LOCAL).toLowerCase() as 'local' | 'google' | 'facebook',
    createdAt: toDate(user.createdAt),
    notificationsEnabled: user.notificationsEnabled ?? true,
    birthDate: user.birthDate ?? undefined,
    gender: user.gender ?? undefined,
    address: user.address ?? undefined,
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
    case 'password':
      return AuthProvider.LOCAL;
    default:
      throw new HttpError(400, 'Nhà cung cấp Firebase không hợp lệ', 'Bad Request');
  }
}

async function clearUserNotifications(userId: string) {
  const snapshot = await getDb()
    .collection('notifications')
    .where('userId', '==', userId)
    .get();

  if (snapshot.empty) return;

  const chunkSize = 400;
  for (let i = 0; i < snapshot.docs.length; i += chunkSize) {
    const chunk = snapshot.docs.slice(i, i + chunkSize);
    const batch = getDb().batch();

    chunk.forEach((doc) => batch.delete(doc.ref));

    await batch.commit();
  }
}

export const authService = {
  async login(dto: LoginDto, adminOnly = false) {
    const email = dto.email.trim().toLowerCase();
    const snapshot = await getDb().collection('users').where('email', '==', email).limit(1).get();
    
    if (snapshot.empty) {
      throw new HttpError(401, 'Email hoặc mật khẩu không đúng', 'Unauthorized');
    }

    const user = { id: snapshot.docs[0].id, ...snapshot.docs[0].data() } as any;

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

    if (user.status === UserStatus.BANNED) {
      throw new HttpError(401, 'Tài khoản đã bị khóa', 'Unauthorized');
    }

    if (adminOnly && user.role !== UserRole.ADMIN) {
      throw new HttpError(401, 'Tài khoản không có quyền quản trị', 'Unauthorized');
    }

    // Kiểm tra trạng thái xác thực email thông qua Firebase Auth
    if (user.role === UserRole.USER && user.authProvider === AuthProvider.LOCAL) {
      try {
        const firebaseUser = await getFirebaseAuth().getUserByEmail(email);
        if (!firebaseUser.emailVerified) {
          throw new HttpError(
            403,
            'Email chưa được xác thực. Vui lòng xác thực email của bạn qua liên kết đã được gửi trước khi đăng nhập.',
            'Forbidden',
          );
        }
      } catch (err: any) {
        if (err instanceof HttpError) throw err;
        console.error('Lỗi kiểm tra trạng thái xác thực email từ Firebase:', err);
      }
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

    const usersColl = getDb().collection('users');
    const snapshot = await usersColl.where('email', '==', email).limit(1).get();
    let user: any;

    if (snapshot.empty) {
      const docRef = usersColl.doc();
      user = {
        id: docRef.id,
        email,
        name: displayName,
        avatar,
        role: UserRole.USER,
        status: UserStatus.ACTIVE,
        authProvider,
        providerUserId: decoded.uid,
        notificationsEnabled: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      await docRef.set(user);
    } else {
      const doc = snapshot.docs[0];
      user = { id: doc.id, ...doc.data() } as any;
      const updatedData = {
        name: (user.name ?? '').trim().length > 0 ? user.name : displayName,
        avatar: user.avatar ?? avatar,
        authProvider,
        providerUserId: decoded.uid,
        updatedAt: new Date(),
      };
      await usersColl.doc(user.id).update(updatedData);
      user = { ...user, ...updatedData };
    }

    if (user.status === UserStatus.BANNED) {
      throw new HttpError(401, 'Tài khoản đã bị khóa', 'Unauthorized');
    }

    return {
      ...signToken(user),
      user: sanitizeUser(user),
    };
  },

  async register(dto: RegisterDto) {
    const email = dto.email.trim().toLowerCase();
    const usersColl = getDb().collection('users');
    const snapshot = await usersColl.where('email', '==', email).limit(1).get();

    if (!snapshot.empty) {
      throw new HttpError(409, 'Email đã được sử dụng', 'Conflict');
    }

    let uid = dto.uid;

    // If UID is not provided, create user on Firebase Auth using the Admin SDK
    if (!uid) {
      try {
        const firebaseUser = await getFirebaseAuth().createUser({
          email: email,
          password: dto.password,
          displayName: dto.name,
        });
        uid = firebaseUser.uid;
      } catch (err: any) {
        // If user already exists in Firebase Auth but not in our Firestore, fetch their UID
        if (err.code === 'auth/email-already-exists') {
          const fbUser = await getFirebaseAuth().getUserByEmail(email);
          uid = fbUser.uid;
        } else {
          throw new HttpError(
            500,
            `Không thể tạo tài khoản trên Firebase Auth: ${err.message}`,
            'Internal Server Error',
          );
        }
      }
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = {
      id: uid,
      email,
      passwordHash,
      name: dto.name,
      avatar: null,
      role: UserRole.USER,
      status: UserStatus.ACTIVE,
      authProvider: AuthProvider.LOCAL,
      providerUserId: uid,
      notificationsEnabled: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await usersColl.doc(uid).set(user);

    return {
      ...signToken(user),
      user: sanitizeUser(user),
    };
  },

  async getProfile(userId: string) {
    const doc = await getDb().collection('users').doc(userId).get();

    if (!doc.exists) {
      throw new HttpError(401, 'Unauthorized', 'Unauthorized');
    }

    const user = { id: doc.id, ...doc.data() } as any;
    return sanitizeUser(user);
  },

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const userRef = getDb().collection('users').doc(userId);
    const updateData: any = {
      name: dto.name,
      updatedAt: new Date(),
    };
    if (dto.avatar !== undefined) {
      updateData.avatar = dto.avatar;
    }
    if (dto.birthDate !== undefined) {
      updateData.birthDate = dto.birthDate;
    }
    if (dto.gender !== undefined) {
      updateData.gender = dto.gender;
    }
    if (dto.address !== undefined) {
      updateData.address = dto.address;
    }

    await userRef.update(updateData);
    const doc = await userRef.get();
    const user = { id: doc.id, ...doc.data() } as any;

    return sanitizeUser(user);
  },

  async updateNotificationPreferences(userId: string, dto: UpdateNotificationPreferencesDto) {
    const userRef = getDb().collection('users').doc(userId);
    const doc = await userRef.get();

    if (!doc.exists) {
      throw new HttpError(401, 'Unauthorized', 'Unauthorized');
    }

    await userRef.update({
      notificationsEnabled: dto.notificationsEnabled,
      updatedAt: new Date(),
    });

    if (!dto.notificationsEnabled) {
      await clearUserNotifications(userId);
    }

    const updated = await userRef.get();
    const user = { id: updated.id, ...updated.data() } as any;

    return sanitizeUser(user);
  },

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const userRef = getDb().collection('users').doc(userId);
    const doc = await userRef.get();

    if (!doc.exists) {
      throw new HttpError(401, 'Unauthorized', 'Unauthorized');
    }

    const user = doc.data() as any;

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
    await userRef.update({
      passwordHash,
      authProvider: AuthProvider.LOCAL,
      updatedAt: new Date(),
    });

    return { success: true };
  },

  generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  },

  async forgotPassword(dto: ForgotPasswordDto) {
    const email = dto.email.trim().toLowerCase();
    const snapshot = await getDb().collection('users').where('email', '==', email).limit(1).get();

    if (snapshot.empty) {
      throw new HttpError(404, 'Không tìm thấy tài khoản với email này', 'Not Found');
    }

    const user = snapshot.docs[0].data() as any;
    const code = authService.generateOtp();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    // Mark previous unused reset codes for this email as used
    const resetsColl = getDb().collection('password_resets');
    const prevResets = await resetsColl.where('email', '==', email).where('used', '==', false).get();
    const batch = getDb().batch();
    prevResets.forEach((doc) => {
      batch.update(doc.ref, { used: true });
    });

    const newResetRef = resetsColl.doc();
    batch.set(newResetRef, {
      id: newResetRef.id,
      email,
      code,
      expiresAt,
      used: false,
      createdAt: new Date(),
    });

    await batch.commit();

    // Gửi email thực sự chứa mã OTP khôi phục mật khẩu
    try {
      await mailService.sendForgotPasswordOtp(email, user.name, code);
    } catch (err) {
      console.error('Lỗi khi gửi email lấy lại mật khẩu OTP:', err);
    }

    return {
      message: 'Mã OTP khôi phục mật khẩu đã được gửi thành công.',
      expiresInMinutes: 15,
    };
  },

  async resetPassword(dto: ResetPasswordDto) {
    const email = dto.email.trim().toLowerCase();
    const resetsColl = getDb().collection('password_resets');
    
    // Fetch resets for email & code to check in memory
    const snapshot = await resetsColl
      .where('email', '==', email)
      .where('code', '==', dto.code)
      .where('used', '==', false)
      .get();

    let record: any = null;
    if (!snapshot.empty) {
      const records = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as any));
      // Sort desc by createdAt to get latest
      records.sort((a, b) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());
      
      const latest = records[0];
      if (toDate(latest.expiresAt).getTime() > Date.now()) {
        record = latest;
      }
    }

    if (!record) {
      throw new HttpError(400, 'Mã OTP không hợp lệ hoặc đã hết hạn', 'Bad Request');
    }

    const usersColl = getDb().collection('users');
    const userSnap = await usersColl.where('email', '==', email).limit(1).get();
    if (userSnap.empty) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    const userId = userSnap.docs[0].id;
    const passwordHash = await bcrypt.hash(dto.newPassword, 10);

    // Đồng bộ mật khẩu mới sang Firebase Auth để đảm bảo đồng bộ đăng nhập
    try {
      const firebaseUser = await getFirebaseAuth().getUserByEmail(email);
      await getFirebaseAuth().updateUser(firebaseUser.uid, {
        password: dto.newPassword,
      });
      console.log(`Đã đồng bộ cập nhật mật khẩu mới sang Firebase Auth cho: ${email}`);
    } catch (err) {
      console.error('Không thể đồng bộ cập nhật mật khẩu sang Firebase Auth:', err);
    }

    const batch = getDb().batch();
    batch.update(usersColl.doc(userId), {
      passwordHash,
      authProvider: AuthProvider.LOCAL,
      updatedAt: new Date(),
    });
    batch.update(resetsColl.doc(record.id), {
      used: true,
    });

    await batch.commit();

    return { success: true };
  },
};