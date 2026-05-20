import { Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service';
import { CreateNotificationDto } from './dto/notification.dto';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  findByUser(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markRead(userId: string, id: string) {
    const item = await this.prisma.notification.findFirst({
      where: { id, userId },
    });
    if (!item) throw new NotFoundException();
    return this.prisma.notification.update({
      where: { id },
      data: { read: true },
    });
  }

  async markAllRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
    return { success: true };
  }

  async create(dto: CreateNotificationDto) {
    if (dto.userId) {
      return this.prisma.notification.create({
        data: { userId: dto.userId, title: dto.title, body: dto.body },
      });
    }

    const users = await this.prisma.user.findMany({
      where: { role: 'USER', status: 'ACTIVE' },
      select: { id: true },
    });

    await this.prisma.notification.createMany({
      data: users.map((u) => ({
        userId: u.id,
        title: dto.title,
        body: dto.body,
      })),
    });

    return { sent: users.length };
  }

  findAllAdmin() {
    return this.prisma.notification.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
      include: { user: { select: { id: true, name: true, email: true } } },
    });
  }
}
