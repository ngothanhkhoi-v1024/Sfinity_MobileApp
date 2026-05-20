import { Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service';
import { CreateFeedbackDto, ReplyFeedbackDto } from './dto/feedback.dto';

@Injectable()
export class FeedbackService {
  constructor(private prisma: PrismaService) {}

  findAll(resolved?: boolean) {
    return this.prisma.feedback.findMany({
      where: resolved !== undefined ? { resolved } : undefined,
      include: { user: { select: { id: true, name: true, email: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  create(userId: string, dto: CreateFeedbackDto) {
    return this.prisma.feedback.create({
      data: { userId, message: dto.message, rating: dto.rating },
    });
  }

  async reply(id: string, dto: ReplyFeedbackDto) {
    await this.findOne(id);
    return this.prisma.feedback.update({
      where: { id },
      data: { reply: dto.reply, resolved: true },
    });
  }

  async resolve(id: string) {
    await this.findOne(id);
    return this.prisma.feedback.update({
      where: { id },
      data: { resolved: true },
    });
  }

  private async findOne(id: string) {
    const item = await this.prisma.feedback.findUnique({ where: { id } });
    if (!item) throw new NotFoundException();
    return item;
  }
}
