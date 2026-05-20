import { HttpError } from '../lib/http-error';
import { prisma } from '../lib/prisma';

export const favoritesService = {
  findByUser(userId: string) {
    return prisma.favorite.findMany({
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
  },

  async add(userId: string, contentId: string) {
    const content = await prisma.content.findUnique({ where: { id: contentId } });
    if (!content) {
      throw new HttpError(404, 'Không tìm thấy nội dung', 'Not Found');
    }

    const existing = await prisma.favorite.findUnique({
      where: { userId_contentId: { userId, contentId } },
    });
    if (existing) {
      throw new HttpError(409, 'Đã có trong yêu thích', 'Conflict');
    }

    return prisma.favorite.create({
      data: { userId, contentId },
      include: { content: true },
    });
  },

  async remove(userId: string, contentId: string) {
    const fav = await prisma.favorite.findUnique({
      where: { userId_contentId: { userId, contentId } },
    });
    if (!fav) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }
    await prisma.favorite.delete({ where: { id: fav.id } });
    return { success: true };
  },
};
