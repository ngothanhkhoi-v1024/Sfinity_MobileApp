import { Injectable, NotFoundException } from '@nestjs/common';
import { ReportStatus } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import { CreateReportDto, ResolveReportDto } from './dto/report.dto';

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  findAll(status?: ReportStatus) {
    return this.prisma.report.findMany({
      where: status ? { status } : undefined,
      include: { user: { select: { id: true, name: true, email: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  create(userId: string, dto: CreateReportDto) {
    return this.prisma.report.create({
      data: {
        userId,
        targetType: dto.targetType,
        targetId: dto.targetId,
        reason: dto.reason,
        description: dto.description,
      },
      include: { user: { select: { id: true, name: true, email: true } } },
    });
  }

  async resolve(id: string, dto: ResolveReportDto) {
    await this.findOne(id);
    return this.prisma.report.update({
      where: { id },
      data: { status: dto.status, resolution: dto.resolution },
    });
  }

  private async findOne(id: string) {
    const report = await this.prisma.report.findUnique({ where: { id } });
    if (!report) throw new NotFoundException('Không tìm thấy báo cáo');
    return report;
  }
}
