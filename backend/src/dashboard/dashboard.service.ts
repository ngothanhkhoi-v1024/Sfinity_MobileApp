import { Injectable } from '@nestjs/common';
import { ContentStatus, UserRole } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async getStats() {
    const [users, admins, contents, published, categories, feedback, pendingFeedback] =
      await Promise.all([
        this.prisma.user.count({ where: { role: UserRole.USER } }),
        this.prisma.user.count({ where: { role: UserRole.ADMIN } }),
        this.prisma.content.count(),
        this.prisma.content.count({ where: { status: ContentStatus.PUBLISHED } }),
        this.prisma.category.count(),
        this.prisma.feedback.count(),
        this.prisma.feedback.count({ where: { resolved: false } }),
      ]);

    return {
      users,
      admins,
      contents,
      publishedContents: published,
      draftContents: contents - published,
      categories,
      feedback,
      pendingFeedback,
    };
  }
}
