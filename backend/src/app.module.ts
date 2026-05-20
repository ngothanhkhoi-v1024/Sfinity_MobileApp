import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from './auth/auth.module';
import { CategoriesModule } from './categories/categories.module';
import { ContentModule } from './content/content.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { FavoritesModule } from './favorites/favorites.module';
import { FeedbackModule } from './feedback/feedback.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PrismaModule } from './prisma/prisma.module';
import { ReportsModule } from './reports/reports.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    UsersModule,
    CategoriesModule,
    ContentModule,
    FavoritesModule,
    FeedbackModule,
    ReportsModule,
    NotificationsModule,
    DashboardModule,
  ],
})
export class AppModule {}
