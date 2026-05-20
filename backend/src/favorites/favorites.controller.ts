import { Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';

import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FavoritesService } from './favorites.service';

@Controller('favorites')
@UseGuards(JwtAuthGuard)
export class FavoritesController {
  constructor(private favorites: FavoritesService) {}

  @Get()
  list(@CurrentUser() user: JwtPayload) {
    return this.favorites.findByUser(user.sub);
  }

  @Post(':contentId')
  add(@CurrentUser() user: JwtPayload, @Param('contentId') contentId: string) {
    return this.favorites.add(user.sub, contentId);
  }

  @Delete(':contentId')
  remove(@CurrentUser() user: JwtPayload, @Param('contentId') contentId: string) {
    return this.favorites.remove(user.sub, contentId);
  }
}
