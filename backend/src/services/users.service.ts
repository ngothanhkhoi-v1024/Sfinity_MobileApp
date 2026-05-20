import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

import { HttpError } from '../lib/http-error';
import { prisma } from '../lib/prisma';
import type { UpdateUserDto } from '../dto/update-user.dto';

export const usersService = {
  mapUser(user: {
    id: string;
    email: string;
    name: string;
    avatar: string | null;
    role: UserRole;
    status: string;
    createdAt: Date;
    updatedAt: Date;
  }) {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      avatar: user.avatar,
      role: user.role.toLowerCase(),
      status: user.status,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  },

  findAll(search?: string) {
    return prisma.user
      .findMany({
        where: search
          ? {
              OR: [
                { email: { contains: search } },
                { name: { contains: search } },
              ],
            }
          : undefined,
        orderBy: { createdAt: 'desc' },
      })
      .then((users) => users.map((u) => usersService.mapUser(u)));
  },

  async findOne(id: string) {
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new HttpError(404, 'Không tìm thấy người dùng', 'Not Found');
    }
    return usersService.mapUser(user);
  },

  async update(id: string, dto: UpdateUserDto) {
    await usersService.findOne(id);
    const user = await prisma.user.update({ where: { id }, data: dto });
    return usersService.mapUser(user);
  },

  async remove(id: string) {
    await usersService.findOne(id);
    await prisma.user.delete({ where: { id } });
    return { success: true };
  },

  async createAdmin(email: string, password: string, name: string) {
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, passwordHash, name, role: UserRole.ADMIN },
    });
    return usersService.mapUser(user);
  },
};
