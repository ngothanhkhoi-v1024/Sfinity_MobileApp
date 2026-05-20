import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ReportStatus, UserRole } from '@prisma/client';

import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CreateReportDto, ResolveReportDto } from './dto/report.dto';
import { ReportsService } from './reports.service';

@Controller('reports')
export class ReportsController {
  constructor(private reports: ReportsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateReportDto) {
    return this.reports.create(user.sub, dto);
  }

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  findAll(@Query('status') status?: ReportStatus) {
    return this.reports.findAll(status);
  }

  @Patch(':id/resolve')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  resolve(@Param('id') id: string, @Body() dto: ResolveReportDto) {
    return this.reports.resolve(id, dto);
  }
}
