import { HttpError } from '../lib/http-error';
import { prisma } from '../lib/prisma';
import type { CreateReportDto, ResolveReportDto } from '../dto/report.dto';
import type { ReportStatus } from '@prisma/client';

export const reportsService = {
  findAll(status?: ReportStatus) {
    return prisma.report.findMany({
      where: status ? { status } : undefined,
      include: { user: { select: { id: true, name: true, email: true } } },
      orderBy: { createdAt: 'desc' },
    });
  },

  create(userId: string, dto: CreateReportDto) {
    return prisma.report.create({
      data: {
        userId,
        targetType: dto.targetType,
        targetId: dto.targetId,
        reason: dto.reason,
        description: dto.description,
      },
      include: { user: { select: { id: true, name: true, email: true } } },
    });
  },

  async resolve(id: string, dto: ResolveReportDto) {
    await reportsService.findOne(id);
    return prisma.report.update({
      where: { id },
      data: { status: dto.status, resolution: dto.resolution },
    });
  },

  async findOne(id: string) {
    const report = await prisma.report.findUnique({ where: { id } });
    if (!report) {
      throw new HttpError(404, 'Không tìm thấy báo cáo', 'Not Found');
    }
    return report;
  },
};
