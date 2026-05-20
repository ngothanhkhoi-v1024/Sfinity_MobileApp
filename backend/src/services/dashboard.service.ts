import { ContentStatus, UserRole } from '@prisma/client';

import { prisma } from '../lib/prisma';

export const dashboardService = {
  async getStats() {
    const [
      users,
      admins,
      contents,
      published,
      categories,
      feedback,
      pendingFeedback,
      pendingReports,
    ] = await Promise.all([
      prisma.user.count({ where: { role: UserRole.USER } }),
      prisma.user.count({ where: { role: UserRole.ADMIN } }),
      prisma.content.count(),
      prisma.content.count({ where: { status: ContentStatus.PUBLISHED } }),
      prisma.category.count(),
      prisma.feedback.count(),
      prisma.feedback.count({ where: { resolved: false } }),
      prisma.report.count({ where: { status: 'PENDING' } }),
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
      pendingReports,
    };
  },
};
