import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { CategoryType } from '../dto/category.dto';
import type { CreateCategoryDto, UpdateCategoryDto } from '../dto/category.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

// Danh mục tài liệu mặc định (DOCUMENT)
const DOCUMENT_CATEGORIES = [
  { name: 'Bài giảng', description: 'Slide bài giảng, tài liệu lý thuyết' },
  { name: 'Đề thi', description: 'Đề thi ôn tập, đề kiểm tra các kỳ' },
  { name: 'Ghi chú', description: 'Ghi chú cá nhân, tóm tắt môn học' },
  { name: 'Khác', description: 'Tài liệu học tập khác' },
];

async function seedCategories() {
  const snapshot = await getDb().collection('categories').get();
  // Chỉ chạy seed nếu collection trống hoàn toàn
  if (!snapshot.empty) return;

  const seedBatch = getDb().batch();
  for (const cat of DOCUMENT_CATEGORIES) {
    const docRef = getDb().collection('categories').doc();
    seedBatch.set(docRef, {
      id: docRef.id,
      name: cat.name,
      description: cat.description,
      type: CategoryType.DOCUMENT,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }
  await seedBatch.commit();
}

export const categoriesService = {
  async findAll(type?: string) {
    await seedCategories();

    const snapshot = await getDb().collection('categories').get();
    const categories = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as any));

    const categoriesWithCount = await Promise.all(
      categories.map(async (cat) => {
        const countSnapshot = await getDb()
          .collection('documents')
          .where('categoryId', '==', cat.id)
          .count()
          .get();

        return {
          id: cat.id,
          name: cat.name,
          description: cat.description ?? null,
          type: cat.type ?? CategoryType.DOCUMENT,
          createdAt: toDate(cat.createdAt),
          updatedAt: toDate(cat.updatedAt),
          _count: {
            documents: countSnapshot.data().count,
          },
        };
      }),
    );

    const sorted = categoriesWithCount.sort((a, b) => a.name.localeCompare(b.name));

    if (type) {
      return sorted.filter((c) => c.type === type);
    }

    return sorted;
  },

  async findOne(id: string) {
    const doc = await getDb().collection('categories').doc(id).get();
    if (!doc.exists) {
      throw new HttpError(404, 'Không tìm thấy danh mục', 'Not Found');
    }
    const cat = { id: doc.id, ...doc.data() } as any;

    const countSnapshot = await getDb()
      .collection('documents')
      .where('categoryId', '==', cat.id)
      .count()
      .get();

    return {
      id: cat.id,
      name: cat.name,
      description: cat.description ?? null,
      type: cat.type ?? CategoryType.DOCUMENT,
      createdAt: toDate(cat.createdAt),
      updatedAt: toDate(cat.updatedAt),
      _count: {
        documents: countSnapshot.data().count,
      },
    };
  },

  async create(dto: CreateCategoryDto) {
    const snapshot = await getDb()
      .collection('categories')
      .where('name', '==', dto.name)
      .limit(1)
      .get();

    if (!snapshot.empty) {
      throw new HttpError(409, 'Tên danh mục đã tồn tại', 'Conflict');
    }

    const docRef = getDb().collection('categories').doc();
    const newCat = {
      id: docRef.id,
      name: dto.name,
      description: dto.description ?? null,
      type: dto.type ?? CategoryType.DOCUMENT,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await docRef.set(newCat);
    return newCat;
  },

  async update(id: string, dto: UpdateCategoryDto) {
    await categoriesService.findOne(id);
    const catRef = getDb().collection('categories').doc(id);

    const updateData: any = {
      ...dto,
      updatedAt: new Date(),
    };

    await catRef.update(updateData);
    const doc = await catRef.get();
    const updated = { id: doc.id, ...doc.data() } as any;

    return {
      id: updated.id,
      name: updated.name,
      description: updated.description ?? null,
      type: updated.type ?? CategoryType.DOCUMENT,
      createdAt: toDate(updated.createdAt),
      updatedAt: toDate(updated.updatedAt),
    };
  },

  async remove(id: string) {
    await categoriesService.findOne(id);
    await getDb().collection('categories').doc(id).delete();
    return { success: true };
  },
};
