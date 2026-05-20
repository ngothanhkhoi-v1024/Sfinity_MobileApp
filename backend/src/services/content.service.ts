import { ContentStatus, UserRole } from '@prisma/client';

import { HttpError } from '../lib/http-error';
import { prisma } from '../lib/prisma';
import type { CreateContentDto, UpdateContentDto } from '../dto/content.dto';

export const contentService = {
  include() {
    return {
      author: { select: { id: true, name: true, email: true } },
      category: { select: { id: true, name: true, slug: true } },
    };
  },

  async findAll(params: {
    search?: string;
    status?: ContentStatus;
    categoryId?: string;
    page?: number;
    limit?: number;
    publishedOnly?: boolean;
  }) {
    const page = params.page ?? 1;
    const limit = params.limit ?? 20;
    const skip = (page - 1) * limit;

    const where = {
      ...(params.publishedOnly ? { status: ContentStatus.PUBLISHED } : {}),
      ...(params.status ? { status: params.status } : {}),
      ...(params.categoryId ? { categoryId: params.categoryId } : {}),
      ...(params.search
        ? {
            OR: [
              { title: { contains: params.search } },
              { body: { contains: params.search } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      prisma.content.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: contentService.include(),
      }),
      prisma.content.count({ where }),
    ]);

    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  },

  async findOne(id: string) {
    const item = await prisma.content.findUnique({
      where: { id },
      include: contentService.include(),
    });
    if (!item) {
      throw new HttpError(404, 'Không tìm thấy nội dung', 'Not Found');
    }
    return item;
  },

  create(authorId: string, dto: CreateContentDto) {
    return prisma.content.create({
      data: { ...dto, authorId },
      include: contentService.include(),
    });
  },

  async update(id: string, dto: UpdateContentDto, userId: string, role: UserRole) {
    const item = await contentService.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }
    return prisma.content.update({
      where: { id },
      data: dto,
      include: contentService.include(),
    });
  },

  async remove(id: string, userId: string, role: UserRole) {
    const item = await contentService.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }
    await prisma.content.delete({ where: { id } });
    return { success: true };
  },
};
