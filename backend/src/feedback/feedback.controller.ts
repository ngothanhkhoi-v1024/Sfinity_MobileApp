import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';

import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CreateFeedbackDto, ReplyFeedbackDto } from './dto/feedback.dto';
import { FeedbackService } from './feedback.service';

@Controller('feedback')
export class FeedbackController {
  constructor(private feedback: FeedbackService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateFeedbackDto) {
    return this.feedback.create(user.sub, dto);
  }

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  findAll(@Query('resolved') resolved?: string) {
    const filter =
      resolved === 'true' ? true : resolved === 'false' ? false : undefined;
    return this.feedback.findAll(filter);
  }

  @Patch(':id/reply')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  reply(@Param('id') id: string, @Body() dto: ReplyFeedbackDto) {
    return this.feedback.reply(id, dto);
  }

  @Patch(':id/resolve')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  resolve(@Param('id') id: string) {
    return this.feedback.resolve(id);
  }
}
