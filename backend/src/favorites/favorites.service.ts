import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FavoritesService {
  constructor(private prisma: PrismaService) {}

  findByUser(userId: string) {
    return this.prisma.favorite.findMany({
      where: { userId },
      include: {
        content: {
          include: {
            category: { select: { id: true, name: true } },
            author: { select: { id: true, name: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async add(userId: string, contentId: string) {
    const content = await this.prisma.content.findUnique({ where: { id: contentId } });
    if (!content) throw new NotFoundException('Không tìm thấy nội dung');

    const existing = await this.prisma.favorite.findUnique({
      where: { userId_contentId: { userId, contentId } },
    });
    if (existing) throw new ConflictException('Đã có trong yêu thích');

    return this.prisma.favorite.create({
      data: { userId, contentId },
      include: { content: true },
    });
  }

  async remove(userId: string, contentId: string) {
    const fav = await this.prisma.favorite.findUnique({
      where: { userId_contentId: { userId, contentId } },
    });
    if (!fav) throw new NotFoundException();
    await this.prisma.favorite.delete({ where: { id: fav.id } });
    return { success: true };
  }
}
