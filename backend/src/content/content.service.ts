import { Injectable, NotFoundException } from '@nestjs/common';
import { ContentStatus, UserRole } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import { CreateContentDto, UpdateContentDto } from './dto/content.dto';

@Injectable()
export class ContentService {
  constructor(private prisma: PrismaService) {}

  private include() {
    return {
      author: { select: { id: true, name: true, email: true } },
      category: { select: { id: true, name: true, slug: true } },
    };
  }

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
      this.prisma.content.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: this.include(),
      }),
      this.prisma.content.count({ where }),
    ]);

    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async findOne(id: string) {
    const item = await this.prisma.content.findUnique({
      where: { id },
      include: this.include(),
    });
    if (!item) throw new NotFoundException('Không tìm thấy nội dung');
    return item;
  }

  create(authorId: string, dto: CreateContentDto) {
    return this.prisma.content.create({
      data: { ...dto, authorId },
      include: this.include(),
    });
  }

  async update(id: string, dto: UpdateContentDto, userId: string, role: UserRole) {
    const item = await this.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new NotFoundException();
    }
    return this.prisma.content.update({
      where: { id },
      data: dto,
      include: this.include(),
    });
  }

  async remove(id: string, userId: string, role: UserRole) {
    const item = await this.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new NotFoundException();
    }
    await this.prisma.content.delete({ where: { id } });
    return { success: true };
  }
}
