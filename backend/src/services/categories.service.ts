import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import type { CreateCategoryDto, UpdateCategoryDto } from '../dto/category.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

export const categoriesService = {
  async findAll() {
    let snapshot = await getDb().collection('categories').get();

    // Tự động seed các danh mục mặc định nếu Firestore đang trống
    if (snapshot.empty) {
      const defaultCategories = [
        { name: 'Bài giảng', slug: 'bai-giang', description: 'Slide bài giảng, tài liệu lý thuyết' },
        { name: 'Đề thi', slug: 'de-thi', description: 'Đề thi ôn tập, đề kiểm tra các kỳ' },
        { name: 'Ghi chú', slug: 'ghi-chu', description: 'Ghi chú cá nhân, tóm tắt môn học' },
        { name: 'Khác', slug: 'khac', description: 'Tài liệu học tập khác' },
      ];

      const batch = getDb().batch();
      for (const cat of defaultCategories) {
        const docRef = getDb().collection('categories').doc();
        batch.set(docRef, {
          id: docRef.id,
          ...cat,
          createdAt: new Date(),
          updatedAt: new Date(),
        });
      }
      await batch.commit();

      // Lấy lại danh sách sau khi đã seed
      snapshot = await getDb().collection('categories').get();
    }

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
          slug: cat.slug,
          description: cat.description ?? null,
          createdAt: toDate(cat.createdAt),
          updatedAt: toDate(cat.updatedAt),
          _count: {
            documents: countSnapshot.data().count,
          },
        };
      }),
    );

    // Sort by name ascending
    categoriesWithCount.sort((a, b) => a.name.localeCompare(b.name));

    return categoriesWithCount;
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
      slug: cat.slug,
      description: cat.description ?? null,
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
      .where('slug', '==', dto.slug)
      .limit(1)
      .get();

    if (!snapshot.empty) {
      throw new HttpError(409, 'Slug đã tồn tại', 'Conflict');
    }

    const docRef = getDb().collection('categories').doc();
    const newCat = {
      id: docRef.id,
      name: dto.name,
      slug: dto.slug,
      description: dto.description ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await docRef.set(newCat);
    return newCat;
  },

  async update(id: string, dto: UpdateCategoryDto) {
    await categoriesService.findOne(id); // Throws if not found
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
      slug: updated.slug,
      description: updated.description ?? null,
      createdAt: toDate(updated.createdAt),
      updatedAt: toDate(updated.updatedAt),
    };
  },

  async remove(id: string) {
    await categoriesService.findOne(id); // Throws if not found
    await getDb().collection('categories').doc(id).delete();
    return { success: true };
  },
};
