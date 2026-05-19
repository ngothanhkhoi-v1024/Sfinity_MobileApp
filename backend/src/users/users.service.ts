import { Injectable, NotFoundException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  private mapUser(user: {
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
  }

  findAll(search?: string) {
    return this.prisma.user.findMany({
      where: search
        ? {
            OR: [
              { email: { contains: search } },
              { name: { contains: search } },
            ],
          }
        : undefined,
      orderBy: { createdAt: 'desc' },
    }).then((users) => users.map((u) => this.mapUser(u)));
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('Không tìm thấy người dùng');
    return this.mapUser(user);
  }

  async update(id: string, dto: UpdateUserDto) {
    await this.findOne(id);
    const user = await this.prisma.user.update({ where: { id }, data: dto });
    return this.mapUser(user);
  }

  async remove(id: string) {
    await this.findOne(id);
    await this.prisma.user.delete({ where: { id } });
    return { success: true };
  }

  async createAdmin(email: string, password: string, name: string) {
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await this.prisma.user.create({
      data: { email, passwordHash, name, role: UserRole.ADMIN },
    });
    return this.mapUser(user);
  }
}
