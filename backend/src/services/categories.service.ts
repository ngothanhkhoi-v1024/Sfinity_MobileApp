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

// Tiện ích địa điểm mặc định (PLACE)
const PLACE_AMENITIES = [
  { name: 'WiFi', slug: 'wifi', description: 'Có kết nối WiFi miễn phí', type: CategoryType.PLACE },
  { name: 'Điều hòa', slug: 'dieu-hoa', description: 'Có điều hòa không khí', type: CategoryType.PLACE },
  { name: 'Ổ cắm', slug: 'o-cam', description: 'Có ổ cắm sạc thiết bị', type: CategoryType.PLACE },
  { name: 'Yên tĩnh', slug: 'yen-tinh', description: 'Khu vực yên tĩnh, phù hợp học tập', type: CategoryType.PLACE },
  { name: 'Mở muộn', slug: 'mo-muon', description: 'Mở cửa đến giờ muộn', type: CategoryType.PLACE },
  { name: 'Giữ xe', slug: 'giu-xe', description: 'Có khu vực giữ xe', type: CategoryType.PLACE },
];

// Danh mục tài liệu mặc định (DOCUMENT)
const DOCUMENT_CATEGORIES = [
  { name: 'Bài giảng', slug: 'bai-giang', description: 'Slide bài giảng, tài liệu lý thuyết', type: CategoryType.DOCUMENT },
  { name: 'Đề thi', slug: 'de-thi', description: 'Đề thi ôn tập, đề kiểm tra các kỳ', type: CategoryType.DOCUMENT },
  { name: 'Ghi chú', slug: 'ghi-chu', description: 'Ghi chú cá nhân, tóm tắt môn học', type: CategoryType.DOCUMENT },
  { name: 'Khác', slug: 'khac', description: 'Tài liệu học tập khác', type: CategoryType.DOCUMENT },
];

async function seedCategories() {
  // Xoá toàn bộ categories cũ và seed lại đúng cấu trúc
  const snapshot = await getDb().collection('categories').get();

  // Xoá tất cả docs cũ
  if (!snapshot.empty) {
    const deleteBatch = getDb().batch();
    for (const doc of snapshot.docs) {
      deleteBatch.delete(doc.ref);
    }
    await deleteBatch.commit();
  }

  // Seed đúng cấu trúc mới: 4 DOCUMENT + 6 PLACE
  const allDefaults = [...DOCUMENT_CATEGORIES, ...PLACE_AMENITIES];
  const seedBatch = getDb().batch();
  for (const cat of allDefaults) {
    const docRef = getDb().collection('categories').doc();
    seedBatch.set(docRef, {
      id: docRef.id,
      ...cat,
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
          slug: cat.slug,
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
      slug: cat.slug,
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
      type: dto.type,
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
      slug: updated.slug,
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
