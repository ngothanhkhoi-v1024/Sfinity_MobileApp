import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { ContentStatus, UserRole } from '../types/enums';
import type { CreateDocumentDto, UpdateDocumentDto } from '../dto/document.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

export const documentService = {
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

    const snapshot = await getDb().collection('documents').get();
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
          ...item,
          id: item.id,
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
    const doc = await getDb().collection('documents').doc(id).get();
    if (!doc.exists) {
      throw new HttpError(404, 'Không tìm thấy tài liệu', 'Not Found');
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
      ...item,
      id: item.id,
      categoryId: item.categoryId ?? null,
      createdAt: toDate(item.createdAt),
      updatedAt: toDate(item.updatedAt),
      author,
      category,
    };
  },

  async create(authorId: string, dto: CreateDocumentDto) {
    const docRef = getDb().collection('documents').doc();
    const type = dto.type ?? 'document';

    const newDocument: any = {
      id: docRef.id,
      title: dto.title,
      body: dto.body,
      status: dto.status ?? ContentStatus.DRAFT,
      authorId,
      categoryId: dto.categoryId ?? null,
      type,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    if (type === 'document') {
      newDocument.fileUrl = dto.fileUrl ?? null;
      newDocument.fileType = dto.fileType ?? null;
      newDocument.fileSize = dto.fileSize ?? null;
      newDocument.subjectCode = dto.subjectCode ?? null;
      newDocument.tags = dto.tags ?? [];
      newDocument.downloadsCount = 0;
      newDocument.likesCount = 0;
    } else if (type === 'place') {
      newDocument.latitude = dto.latitude ?? null;
      newDocument.longitude = dto.longitude ?? null;
      newDocument.address = dto.address ?? null;
    }

    await docRef.set(newDocument);
    return documentService.findOne(docRef.id);
  },

  async update(id: string, dto: UpdateDocumentDto, userId: string, role: UserRole) {
    const item = await documentService.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    const docRef = getDb().collection('documents').doc(id);
    const updateData: any = {
      updatedAt: new Date(),
    };

    // Filter out undefined properties to prevent Firestore crash
    for (const [key, value] of Object.entries(dto)) {
      if (value !== undefined) {
        updateData[key] = value;
      }
    }

    await docRef.update(updateData);
    return documentService.findOne(id);
  },

  async remove(id: string, userId: string, role: UserRole) {
    const item = await documentService.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    await getDb().collection('documents').doc(id).delete();
    return { success: true };
  },
};
