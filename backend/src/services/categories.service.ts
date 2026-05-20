import { HttpError } from '../lib/http-error';
import { prisma } from '../lib/prisma';
import type { CreateCategoryDto, UpdateCategoryDto } from '../dto/category.dto';

export const categoriesService = {
  findAll() {
    return prisma.category.findMany({
      orderBy: { name: 'asc' },
      include: { _count: { select: { contents: true } } },
    });
  },

  async findOne(id: string) {
    const cat = await prisma.category.findUnique({
      where: { id },
      include: { _count: { select: { contents: true } } },
    });
    if (!cat) {
      throw new HttpError(404, 'Không tìm thấy danh mục', 'Not Found');
    }
    return cat;
  },

  async create(dto: CreateCategoryDto) {
    const exists = await prisma.category.findUnique({ where: { slug: dto.slug } });
    if (exists) {
      throw new HttpError(409, 'Slug đã tồn tại', 'Conflict');
    }
    return prisma.category.create({ data: dto });
  },

  async update(id: string, dto: UpdateCategoryDto) {
    await categoriesService.findOne(id);
    return prisma.category.update({ where: { id }, data: dto });
  },

  async remove(id: string) {
    await categoriesService.findOne(id);
    await prisma.category.delete({ where: { id } });
    return { success: true };
  },
};
