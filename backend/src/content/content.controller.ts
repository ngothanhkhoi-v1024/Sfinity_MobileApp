import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ContentStatus, UserRole } from '@prisma/client';

import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ContentService } from './content.service';
import { CreateContentDto, UpdateContentDto } from './dto/content.dto';

@Controller('content')
export class ContentController {
  constructor(private content: ContentService) {}

  @Get()
  findAll(
    @Query('search') search?: string,
    @Query('status') status?: ContentStatus,
    @Query('categoryId') categoryId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('publishedOnly') publishedOnly?: string,
  ) {
    return this.content.findAll({
      search,
      status,
      categoryId,
      page: page ? Number(page) : 1,
      limit: limit ? Number(limit) : 20,
      publishedOnly: publishedOnly === 'true',
    });
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.content.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateContentDto) {
    return this.content.create(user.sub, dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  update(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateContentDto,
  ) {
    return this.content.update(id, dto, user.sub, user.role as UserRole);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  remove(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.content.remove(id, user.sub, user.role as UserRole);
  }

  @Patch(':id/publish')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  publish(@Param('id') id: string) {
    return this.content.update(id, { status: ContentStatus.PUBLISHED }, '', UserRole.ADMIN);
  }

  @Patch(':id/unpublish')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  unpublish(@Param('id') id: string) {
    return this.content.update(id, { status: ContentStatus.DRAFT }, '', UserRole.ADMIN);
  }
}
