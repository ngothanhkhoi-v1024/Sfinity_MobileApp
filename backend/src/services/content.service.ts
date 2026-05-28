import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { ContentStatus, UserRole } from '../types/enums';
import type { CreateContentDto, UpdateContentDto } from '../dto/content.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

export const contentService = {
  async findAll(params: {
    search?: string;
    status?: ContentStatus;
    categoryId?: string;
    page?: number;
    limit?: number;
    publishedOnly?: boolean;
  }) {
    const page = params.page ?? 1;
    const limit = params.limit ?? 20;
    const skip = (page - 1) * limit;

    const snapshot = await getDb().collection('contents').get();
    let items = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as any));

    // Filter status
    if (params.publishedOnly) {
      items = items.filter((item) => item.status === ContentStatus.PUBLISHED);
    } else if (params.status) {
      items = items.filter((item) => item.status === params.status);
    }

    // Filter category
    if (params.categoryId) {
      items = items.filter((item) => item.categoryId === params.categoryId);
    }

    // Filter search term case-insensitively
    if (params.search) {
      const term = params.search.toLowerCase();
      items = items.filter(
        (item) =>
          (item.title && item.title.toLowerCase().includes(term)) ||
          (item.body && item.body.toLowerCase().includes(term)),
      );
    }

    // Sort by createdAt desc in memory
    items.sort((a, b) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());

    const total = items.length;
    const paginatedItems = items.slice(skip, skip + limit);

    // Resolve author and category relationships for the paginated slice
    const resolvedItems = await Promise.all(
      paginatedItems.map(async (item) => {
        let author = null;
        if (item.authorId) {
          const authorDoc = await getDb().collection('users').doc(item.authorId).get();
          if (authorDoc.exists) {
            const a = authorDoc.data() as any;
            author = { id: authorDoc.id, name: a.name, email: a.email };
          }
        }

        let category = null;
        if (item.categoryId) {
          const categoryDoc = await getDb().collection('categories').doc(item.categoryId).get();
          if (categoryDoc.exists) {
            const c = categoryDoc.data() as any;
            category = { id: categoryDoc.id, name: c.name, slug: c.slug };
          }
        }

        return {
          id: item.id,
          title: item.title,
          body: item.body,
          status: item.status,
          authorId: item.authorId,
          categoryId: item.categoryId ?? null,
          createdAt: toDate(item.createdAt),
          updatedAt: toDate(item.updatedAt),
          author,
          category,
        };
      }),
    );

    return { items: resolvedItems, total, page, limit, totalPages: Math.ceil(total / limit) };
  },

  async findOne(id: string) {
    const doc = await getDb().collection('contents').doc(id).get();
    if (!doc.exists) {
      throw new HttpError(404, 'Không tìm thấy nội dung', 'Not Found');
    }
    const item = { id: doc.id, ...doc.data() } as any;

    let author = null;
    if (item.authorId) {
      const authorDoc = await getDb().collection('users').doc(item.authorId).get();
      if (authorDoc.exists) {
        const a = authorDoc.data() as any;
        author = { id: authorDoc.id, name: a.name, email: a.email };
      }
    }

    let category = null;
    if (item.categoryId) {
      const categoryDoc = await getDb().collection('categories').doc(item.categoryId).get();
      if (categoryDoc.exists) {
        const c = categoryDoc.data() as any;
        category = { id: categoryDoc.id, name: c.name, slug: c.slug };
      }
    }

    return {
      id: item.id,
      title: item.title,
      body: item.body,
      status: item.status,
      authorId: item.authorId,
      categoryId: item.categoryId ?? null,
      createdAt: toDate(item.createdAt),
      updatedAt: toDate(item.updatedAt),
      author,
      category,
    };
  },

  async create(authorId: string, dto: CreateContentDto) {
    const docRef = getDb().collection('contents').doc();
    const newContent = {
      id: docRef.id,
      title: dto.title,
      body: dto.body,
      status: dto.status ?? ContentStatus.DRAFT,
      authorId,
      categoryId: dto.categoryId ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await docRef.set(newContent);
    return contentService.findOne(docRef.id);
  },

  async update(id: string, dto: UpdateContentDto, userId: string, role: UserRole) {
    const item = await contentService.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    const docRef = getDb().collection('contents').doc(id);
    const updateData: any = {
      ...dto,
      updatedAt: new Date(),
    };

    await docRef.update(updateData);
    return contentService.findOne(id);
  },

  async remove(id: string, userId: string, role: UserRole) {
    const item = await contentService.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    await getDb().collection('contents').doc(id).delete();
    return { success: true };
  },
};
