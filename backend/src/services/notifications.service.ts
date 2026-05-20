import { HttpError } from '../lib/http-error';
import { prisma } from '../lib/prisma';
import type { CreateNotificationDto } from '../dto/notification.dto';

export const notificationsService = {
  findByUser(userId: string) {
    return prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  },

  async markRead(userId: string, id: string) {
    const item = await prisma.notification.findFirst({
      where: { id, userId },
    });
    if (!item) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }
    return prisma.notification.update({
      where: { id },
      data: { read: true },
    });
  },

  async markAllRead(userId: string) {
    await prisma.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
    return { success: true };
  },

  async create(dto: CreateNotificationDto) {
    if (dto.userId) {
      return prisma.notification.create({
        data: { userId: dto.userId, title: dto.title, body: dto.body },
      });
    }

    const users = await prisma.user.findMany({
      where: { role: 'USER', status: 'ACTIVE' },
      select: { id: true },
    });

    await prisma.notification.createMany({
      data: users.map((u) => ({
        userId: u.id,
        title: dto.title,
        body: dto.body,
      })),
    });

    return { sent: users.length };
  },

  findAllAdmin() {
    return prisma.notification.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
      include: { user: { select: { id: true, name: true, email: true } } },
    });
  },
};
