import * as bcrypt from 'bcrypt';

import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { AuthProvider, UserRole, UserStatus } from '../types/enums';
import type { UpdateUserDto } from '../dto/update-user.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

export const usersService = {
  mapUser(user: {
    id: string;
    email: string;
    name: string;
    avatar: string | null;
    role: UserRole;
    status: string;
    notificationsEnabled?: boolean;
    gender?: string;
    birthDate?: string;
    address?: string;
    createdAt: any;
    updatedAt: any;
  }) {
    return {
      id: user.id,
      email: user.email ?? '',
      name: user.name ?? 'Unknown',
      avatar: user.avatar ?? null,
      role: (user.role ?? 'USER').toLowerCase(),
      status: user.status ?? 'ACTIVE',
      notificationsEnabled: user.notificationsEnabled ?? true,
      gender: user.gender ?? '',
      birthDate: user.birthDate ?? '',
      address: user.address ?? '',
      createdAt: toDate(user.createdAt),
      updatedAt: toDate(user.updatedAt),
    };
  },

  async findAll(search?: string) {
    const snapshot = await getDb().collection('users').get();
    let users = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as any));

    if (search) {
      const term = search.toLowerCase();
      users = users.filter(
        (u) =>
          (u.email && u.email.toLowerCase().includes(term)) ||
          (u.name && u.name.toLowerCase().includes(term)),
      );
    }

    // Sort by createdAt desc in memory
    users.sort((a, b) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());

    return users.map((u) => usersService.mapUser(u));
  },

  async findOne(id: string) {
    const doc = await getDb().collection('users').doc(id).get();
    if (!doc.exists) {
      throw new HttpError(404, 'Không tìm thấy người dùng', 'Not Found');
    }
    return usersService.mapUser({ id: doc.id, ...doc.data() } as any);
  },

  async update(id: string, dto: UpdateUserDto) {
    await usersService.findOne(id); // Throws if not found
    const userRef = getDb().collection('users').doc(id);

    await userRef.update({
      ...dto,
      updatedAt: new Date(),
    });

    const doc = await userRef.get();
    return usersService.mapUser({ id: doc.id, ...doc.data() } as any);
  },

  async remove(id: string) {
    await usersService.findOne(id); // Throws if not found
    await getDb().collection('users').doc(id).delete();
    return { success: true };
  },

  async createAdmin(email: string, password: string, name: string) {
    const emailLower = email.trim().toLowerCase();

    // Check if user already exists
    const snapshot = await getDb()
      .collection('users')
      .where('email', '==', emailLower)
      .limit(1)
      .get();

    if (!snapshot.empty) {
      throw new HttpError(409, 'Email đã được sử dụng', 'Conflict');
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const docRef = getDb().collection('users').doc();
    const user = {
      id: docRef.id,
      email: emailLower,
      passwordHash,
      name,
      avatar: null,
      role: UserRole.ADMIN,
      status: UserStatus.ACTIVE,
      authProvider: AuthProvider.LOCAL,
      notificationsEnabled: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await docRef.set(user);
    return usersService.mapUser(user);
  },
};
