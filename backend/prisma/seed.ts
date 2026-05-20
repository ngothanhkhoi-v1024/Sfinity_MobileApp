import { PrismaClient, ContentStatus, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash('admin123', 10);

  const admin = await prisma.user.upsert({
    where: { email: 'admin@sfinity.com' },
    update: {},
    create: {
      email: 'admin@sfinity.com',
      passwordHash,
      name: 'Quản trị viên',
      role: UserRole.ADMIN,
    },
  });

  const userPassword = await bcrypt.hash('user123', 10);
  const user = await prisma.user.upsert({
    where: { email: 'user@sfinity.com' },
    update: {},
    create: {
      email: 'user@sfinity.com',
      passwordHash: userPassword,
      name: 'Người dùng demo',
      role: UserRole.USER,
    },
  });

  const category = await prisma.category.upsert({
    where: { slug: 'tin-tuc' },
    update: {},
    create: {
      name: 'Tin tức',
      slug: 'tin-tuc',
      description: 'Bài viết tin tức',
    },
  });

  const existing = await prisma.content.count();
  if (existing === 0) {
    await prisma.content.createMany({
      data: [
        {
          title: 'Chào mừng đến Sfinity',
          body: 'Đây là bài viết mẫu đầu tiên trên hệ thống.',
          status: ContentStatus.PUBLISHED,
          authorId: admin.id,
          categoryId: category.id,
        },
        {
          title: 'Hướng dẫn sử dụng app',
          body: 'Đăng nhập, xem nội dung, thêm yêu thích và gửi phản hồi.',
          status: ContentStatus.PUBLISHED,
          authorId: user.id,
          categoryId: category.id,
        },
        {
          title: 'Bản nháp nội dung',
          body: 'Nội dung chưa xuất bản.',
          status: ContentStatus.DRAFT,
          authorId: admin.id,
        },
      ],
    });
  }

  console.log('Seed OK:', { admin: admin.email, user: user.email });
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
