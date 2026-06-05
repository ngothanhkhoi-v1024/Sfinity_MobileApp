import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { notificationsService } from './notifications.service';
import { settingsService } from './settings.service';
import { placeService } from './place.service';
import { ContentStatus, UserRole } from '../types/enums';
import type { CreateDocumentDto, UpdateDocumentDto } from '../dto/document.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

const itemMatchesPlaceId = (item: any, placeId: string): boolean =>
  item.placeId === placeId;

async function assertPlaceOwnerForDocument(
  placeId: string,
  userId: string,
  role: UserRole,
): Promise<void> {
  const place = await placeService.findOne(placeId);
  if (role !== UserRole.ADMIN && place.authorId !== userId) {
    throw new HttpError(
      403,
      'Chỉ chủ địa điểm mới được đăng tài liệu tại đây',
      'Forbidden',
    );
  }
}

export const documentService = {
  async findAll(params: {
    search?: string;
    status?: ContentStatus;
    categoryId?: string;
    authorId?: string;
    placeId?: string;
    tags?: string;
    page?: number;
    limit?: number;
    publishedOnly?: boolean;
  }) {
    const page = params.page ?? 1;
    const limit = params.limit ?? 20;
    const skip = (page - 1) * limit;

    const snapshot = await getDb().collection('documents').get();
    let items = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as any));

    if (params.publishedOnly) {
      items = items.filter((item) => item.status === ContentStatus.PUBLISHED);
    } else if (params.status) {
      items = items.filter((item) => item.status === params.status);
    }

    if (params.categoryId) {
      items = items.filter((item) => item.categoryId === params.categoryId);
    }

    if (params.authorId) {
      items = items.filter((item) => item.authorId === params.authorId);
    }

    if (params.placeId) {
      items = items.filter((item) => itemMatchesPlaceId(item, params.placeId!));
    }

    if (params.search) {
      const term = params.search.toLowerCase();
      items = items.filter(
        (item) =>
          (item.title && item.title.toLowerCase().includes(term)) ||
          (item.body && item.body.toLowerCase().includes(term))
      );
    }

    items.sort((a, b) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());

    const total = items.length;
    const paginatedItems = items.slice(skip, skip + limit);

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
            category = { id: categoryDoc.id, name: c.name };
          }
        }

        return {
          ...item,
          id: item.id,
          type: 'document', // Inject type for compatibility
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
        category = { id: categoryDoc.id, name: c.name };
      }
    }

    return {
      ...item,
      id: item.id,
      type: 'document', // Inject type for compatibility
      categoryId: item.categoryId ?? null,
      createdAt: toDate(item.createdAt),
      updatedAt: toDate(item.updatedAt),
      author,
      category,
    };
  },

  async create(authorId: string, dto: CreateDocumentDto, role: UserRole = UserRole.USER) {
    const docRef = getDb().collection('documents').doc();

    if (dto.placeId) {
      await assertPlaceOwnerForDocument(dto.placeId, authorId, role);
    }

    let initialStatus = dto.status ?? ContentStatus.PENDING;
    if (role !== UserRole.ADMIN) {
      if (initialStatus === ContentStatus.PUBLISHED || initialStatus === ContentStatus.REJECTED || initialStatus === ContentStatus.HIDDEN) {
        initialStatus = ContentStatus.PENDING;
      }
      const settings = await settingsService.get();
      const autoApprove = settings.autoApproveDocuments;
      if ((initialStatus === ContentStatus.PENDING || initialStatus === ContentStatus.DRAFT) && autoApprove) {
        initialStatus = ContentStatus.PUBLISHED;
      }
    }

    const newDocument: any = {
      id: docRef.id,
      title: dto.title,
      body: dto.body ?? '',
      status: initialStatus,
      authorId,
      categoryId: dto.categoryId ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    newDocument.fileUrl = dto.fileUrl ?? null;
    newDocument.fileType = dto.fileType ?? null;
    newDocument.fileSize = dto.fileSize ?? null;
    newDocument.subjectCode = dto.subjectCode ?? null;
    newDocument.tags = dto.tags ?? [];
    newDocument.downloadsCount = 0;
    newDocument.likesCount = 0;
    if (dto.placeId) {
      newDocument.placeId = dto.placeId;
    }

    await docRef.set(newDocument);
    return documentService.findOne(docRef.id);
  },

  async update(id: string, dto: UpdateDocumentDto, userId: string, role: UserRole) {
    const item = await documentService.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    if (dto.placeId) {
      await assertPlaceOwnerForDocument(dto.placeId, userId, role);
    }

    const docRef = getDb().collection('documents').doc(id);
    const updateData: any = {
      updatedAt: new Date(),
    };

    let hasContentChanges = false;
    for (const [key, value] of Object.entries(dto)) {
      if (value !== undefined) {
        updateData[key] = value;
        if (['title', 'body', 'fileUrl', 'categoryId', 'subjectCode', 'tags'].includes(key)) {
          hasContentChanges = true;
        }
      }
    }

    if (role !== UserRole.ADMIN) {
      if (dto.status === ContentStatus.PUBLISHED || dto.status === ContentStatus.REJECTED || dto.status === ContentStatus.HIDDEN) {
        updateData.status = ContentStatus.PENDING;
      }
      if (hasContentChanges && (item.status === ContentStatus.PUBLISHED || item.status === ContentStatus.REJECTED || item.status === ContentStatus.HIDDEN)) {
        updateData.status = ContentStatus.PENDING;
        const settings = await settingsService.get();
        const autoApprove = settings.autoApproveDocuments;
        if (autoApprove) {
          updateData.status = ContentStatus.PUBLISHED;
        }
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

  async incrementDownload(id: string) {
    const docRef = getDb().collection('documents').doc(id);
    const doc = await docRef.get();
    if (!doc.exists) {
      throw new HttpError(404, 'Không tìm thấy tài liệu', 'Not Found');
    }
    const currentCount = (doc.data() as any).downloadsCount ?? 0;
    await docRef.update({
      downloadsCount: currentCount + 1,
      updatedAt: new Date(),
    });
    return documentService.findOne(id);
  },

  async adminHide(id: string, reason: string) {
    const item = await documentService.findOne(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('documents').doc(id);
    await docRef.update({
      status: ContentStatus.HIDDEN,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã bị ẩn`,
      body: `Admin đã ẩn tài liệu của bạn. Lý do: ${reason}`,
    });

    return documentService.findOne(id);
  },

  async adminReject(id: string, reason: string) {
    const item = await documentService.findOne(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('documents').doc(id);
    await docRef.update({
      status: ContentStatus.REJECTED,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Tài liệu "${item.title}" bị từ chối duyệt`,
      body: `Admin đã từ chối duyệt tài liệu của bạn. Lý do: ${reason}`,
    });

    return documentService.findOne(id);
  },

  async adminDelete(id: string, reason: string) {
    const item = await documentService.findOne(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã bị xóa`,
      body: `Admin đã xóa tài liệu của bạn. Lý do: ${reason}`,
    });

    await getDb().collection('documents').doc(id).delete();
    return { success: true };
  },

  async adminUnhide(id: string, note?: string) {
    const item = await documentService.findOne(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('documents').doc(id);
    await docRef.update({
      status: ContentStatus.PUBLISHED,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã được hiển thị lại`,
      body: note
        ? `Admin đã bỏ ẩn tài liệu của bạn. Ghi chú: ${note}`
        : `Admin đã bỏ ẩn và khôi phục tài liệu của bạn.`,
    });

    return documentService.findOne(id);
  },

  async adminApprove(id: string, note?: string) {
    const item = await documentService.findOne(id);

    const docRef = getDb().collection('documents').doc(id);
    await docRef.update({
      status: ContentStatus.PUBLISHED,
      updatedAt: new Date(),
    });

    if (item.authorId) {
      await notificationsService.create({
        userId: item.authorId,
        title: `Nội dung "${item.title}" đã được duyệt`,
        body: note
          ? `Tài liệu của bạn đã được admin duyệt và xuất bản. Ghi chú: ${note}`
          : `Tài liệu của bạn đã được admin duyệt và xuất bản.`,
      });
    }

    return documentService.findOne(id);
  },
};
