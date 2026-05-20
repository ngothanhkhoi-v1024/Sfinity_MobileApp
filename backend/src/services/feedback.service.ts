import { HttpError } from '../lib/http-error';
import { prisma } from '../lib/prisma';
import type { CreateFeedbackDto, ReplyFeedbackDto } from '../dto/feedback.dto';

export const feedbackService = {
  findAll(resolved?: boolean) {
    return prisma.feedback.findMany({
      where: resolved !== undefined ? { resolved } : undefined,
      include: { user: { select: { id: true, name: true, email: true } } },
      orderBy: { createdAt: 'desc' },
    });
  },

  create(userId: string, dto: CreateFeedbackDto) {
    return prisma.feedback.create({
      data: { userId, message: dto.message, rating: dto.rating },
    });
  },

  async reply(id: string, dto: ReplyFeedbackDto) {
    await feedbackService.findOne(id);
    return prisma.feedback.update({
      where: { id },
      data: { reply: dto.reply, resolved: true },
    });
  },

  async resolve(id: string) {
    await feedbackService.findOne(id);
    return prisma.feedback.update({
      where: { id },
      data: { resolved: true },
    });
  },

  async findOne(id: string) {
    const item = await prisma.feedback.findUnique({ where: { id } });
    if (!item) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }
    return item;
  },
};
