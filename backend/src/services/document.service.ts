import { getDb } from '../lib/firebase';
import { HttpError } from '../lib/http-error';
import { checkContentModeration, extractTextFromPdf } from '../lib/moderation';
import { notificationsService } from './notifications.service';
import { settingsService } from './settings.service';
import { logger } from '../lib/logger';
import { placeService } from './place.service';
import {
  applyContentState,
  deriveRequestedModeration,
  deriveRequestedVisibility,
  isPubliclyVisible,
  normalizeContentState,
  sanitizeAdminModeration,
} from '../lib/content-state';
import {
  ContentModerationStatus,
  ContentVisibility,
  UserRole,
} from '../types/enums';
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
  const place = await placeService.findOne(placeId, userId, role);
  if (role !== UserRole.ADMIN && place.authorId !== userId) {
    throw new HttpError(
      403,
      'Chỉ chủ địa điểm mới được đăng tài liệu tại đây',
      'Forbidden',
    );
  }
}

function isOwnerOrAdmin(item: any, viewerId?: string, viewerRole?: UserRole): boolean {
  return viewerRole === UserRole.ADMIN || (!!viewerId && item.authorId === viewerId);
}

function canViewDocument(item: any, viewerId?: string, viewerRole?: UserRole): boolean {
  return isOwnerOrAdmin(item, viewerId, viewerRole) || isPubliclyVisible(item);
}

function fileNameFromUrl(url?: string | null): string {
  if (!url) return '';
  try {
    const path = url.split('?')[0];
    return decodeURIComponent(path.split('/').pop() ?? '');
  } catch {
    return '';
  }
}

async function enrichDocument(item: any) {
  const normalized = applyContentState(item);

  let author = null;
  if (normalized.authorId) {
    const authorDoc = await getDb().collection('users').doc(normalized.authorId).get();
    if (authorDoc.exists) {
      const a = authorDoc.data() as any;
      author = { id: authorDoc.id, name: a.name, email: a.email };
    }
  }

  let category = null;
  if (normalized.categoryId) {
    const categoryDoc = await getDb().collection('categories').doc(normalized.categoryId).get();
    if (categoryDoc.exists) {
      const c = categoryDoc.data() as any;
      category = { id: categoryDoc.id, name: c.name };
    }
  }

  let avgRating = normalized.avgRating;
  let reviewCount = normalized.reviewCount;

  if (avgRating === undefined || reviewCount === undefined) {
    const reviewsSnapshot = await getDb()
      .collection('document_reviews')
      .where('documentId', '==', normalized.id)
      .get();
    const ratings = reviewsSnapshot.docs
      .map((doc) => doc.data().rating as number)
      .filter((r) => typeof r === 'number' && r >= 1 && r <= 5);
    reviewCount = ratings.length;
    avgRating =
      reviewCount > 0
        ? Math.round((ratings.reduce((a, b) => a + b, 0) / reviewCount) * 10) / 10
        : null;

    await getDb()
      .collection('documents')
      .doc(normalized.id)
      .update({
        avgRating: avgRating ?? null,
        reviewCount,
      })
      .catch((err) => logger.error({ err }, 'Error caching document rating'));
  }

  return {
    ...normalized,
    id: normalized.id,
    type: 'document',
    categoryId: normalized.categoryId ?? null,
    createdAt: toDate(normalized.createdAt),
    updatedAt: toDate(normalized.updatedAt),
    author,
    category,
    avgRating: avgRating ?? null,
    reviewCount: reviewCount ?? 0,
  };
}

async function getDocumentRaw(id: string) {
  const doc = await getDb().collection('documents').doc(id).get();
  if (!doc.exists) {
    throw new HttpError(404, 'Không tìm thấy tài liệu', 'Not Found');
  }
  return { id: doc.id, ...doc.data() } as any;
}

export const documentService = {
  async findAll(params: {
    search?: string;
    categoryId?: string;
    authorId?: string;
    placeId?: string;
    subjectCode?: string;

    page?: number;
    limit?: number;
    publishedOnly?: boolean;
    viewerId?: string;
    viewerRole?: UserRole;
  }) {
    const page = params.page ?? 1;
    const limit = params.limit ?? 20;
    const skip = (page - 1) * limit;

    const snapshot = await getDb().collection('documents').get();
    let items = snapshot.docs.map((doc) =>
      applyContentState({ id: doc.id, ...doc.data() } as any),
    );

    const canReadAuthorWorkspace =
      !!params.authorId &&
      (params.viewerRole === UserRole.ADMIN || params.viewerId === params.authorId);

    items = items.filter((item) => {
      if (params.authorId && item.authorId !== params.authorId) {
        return false;
      }

      if (params.publishedOnly) {
        return isPubliclyVisible(item);
      }

      if (canReadAuthorWorkspace || params.viewerRole === UserRole.ADMIN) {
        return true;
      }

      return isPubliclyVisible(item);
    });



    if (params.categoryId) {
      items = items.filter((item) => item.categoryId === params.categoryId);
    }

    if (params.placeId) {
      items = items.filter((item) => itemMatchesPlaceId(item, params.placeId!));
    }

    if (params.subjectCode) {
      const code = params.subjectCode.toLowerCase();
      items = items.filter(
        (item) => item.subjectCode && item.subjectCode.toLowerCase() === code,
      );
    }

    if (params.search) {
      const term = params.search.toLowerCase();
      items = items.filter((item) => {
        const titleMatch = item.title && item.title.toLowerCase().includes(term);
        const bodyMatch = item.body && item.body.toLowerCase().includes(term);
        const fileMatch = fileNameFromUrl(item.fileUrl).toLowerCase().includes(term);
        const subjectMatch =
          item.subjectCode && item.subjectCode.toLowerCase().includes(term);
        return titleMatch || bodyMatch || fileMatch || subjectMatch;
      });
    }

    items.sort((a, b) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());

    const total = items.length;
    const paginatedItems = items.slice(skip, skip + limit);
    const resolvedItems = await Promise.all(paginatedItems.map((item) => enrichDocument(item)));

    return {
      items: resolvedItems,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  },

  async findOne(id: string, viewerId?: string, viewerRole?: UserRole) {
    const item = await getDocumentRaw(id);
    if (!canViewDocument(item, viewerId, viewerRole)) {
      throw new HttpError(404, 'Không tìm thấy tài liệu', 'Not Found');
    }
    return enrichDocument(item);
  },

  async create(authorId: string, dto: CreateDocumentDto, role: UserRole = UserRole.USER) {
    const docRef = getDb().collection('documents').doc();

    if (dto.placeId) {
      await assertPlaceOwnerForDocument(dto.placeId, authorId, role);
    }

    const requestedVisibility = deriveRequestedVisibility(dto) ?? ContentVisibility.PUBLIC;
    const settings = role === UserRole.ADMIN ? null : await settingsService.get();
    const autoApprove = settings?.autoApproveDocuments ?? false;

    const state =
      requestedVisibility === ContentVisibility.PRIVATE
        ? {
            visibility: ContentVisibility.PRIVATE,
            moderationStatus: ContentModerationStatus.NONE,
          }
        : role === UserRole.ADMIN
          ? {
              visibility: ContentVisibility.PUBLIC,
              moderationStatus: sanitizeAdminModeration(deriveRequestedModeration(dto)),
            }
          : {
              visibility: ContentVisibility.PUBLIC,
              moderationStatus: autoApprove
                ? ContentModerationStatus.APPROVED
                : ContentModerationStatus.PENDING,
            };

    let moderationStatus = state.moderationStatus;
    let aiRejected = false;
    let rejectionReason = null;

    if (role !== UserRole.ADMIN && state.visibility === ContentVisibility.PUBLIC) {
      let textToScan = `${dto.title} ${dto.body ?? ''}`;
      
      // Nếu có đính kèm file PDF, tải và đọc nội dung văn bản bên trong file PDF đó
      if (dto.fileUrl && (dto.fileType === 'pdf' || dto.fileUrl.toLowerCase().includes('.pdf'))) {
        try {
          const pdfText = await extractTextFromPdf(dto.fileUrl);
          if (pdfText) {
            textToScan += ` [PDF Content: ${pdfText}]`;
          }
        } catch (err) {
          logger.error({ fileUrl: dto.fileUrl, err }, 'PDF Extraction Error during Create');
        }
      }

      const modResult = await checkContentModeration(textToScan);
      if (modResult.flagged) {
        moderationStatus = ContentModerationStatus.REJECTED;
        aiRejected = true;
        rejectionReason = `Tự động từ chối bởi AI. Vi phạm danh mục: ${modResult.categories.join(', ')}`;
      } else if (modResult.error) {
        // Fallback to PENDING if AI moderation fails (e.g. quota limit, api key issue) to prevent auto-approving bad files
        moderationStatus = ContentModerationStatus.PENDING;
        rejectionReason = `Lỗi hệ thống khi kiểm duyệt tự động: ${modResult.error}. Cần chờ quản trị viên duyệt thủ công.`;
      }
    }

    const newDocument: any = {
      id: docRef.id,
      title: dto.title,
      body: dto.body ?? '',
      visibility: state.visibility,
      moderationStatus,
      aiRejected,
      rejectionReason,
      authorId,
      categoryId: dto.categoryId ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    newDocument.fileUrl = dto.fileUrl ?? null;
    newDocument.fileType = dto.fileType ?? null;
    newDocument.fileSize = dto.fileSize ?? null;
    newDocument.subjectCode = dto.subjectCode ?? null;

    newDocument.downloadsCount = 0;
    newDocument.likesCount = 0;
    if (dto.placeId) {
      newDocument.placeId = dto.placeId;
    }

    await docRef.set(newDocument);
    return documentService.findOne(docRef.id, authorId, role);
  },

  async update(id: string, dto: UpdateDocumentDto, userId: string, role: UserRole) {
    const item = await getDocumentRaw(id);
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
    const currentState = normalizeContentState(item);

    let hasContentChanges = false;
    for (const [key, value] of Object.entries(dto)) {
      if (value !== undefined) {
        updateData[key] = value;
        if (
          [
            'title',
            'body',
            'fileUrl',
            'fileType',
            'fileSize',
            'categoryId',
            'subjectCode',
          ].includes(key)
        ) {
          hasContentChanges = true;
        }
      }
    }

    const requestedVisibility = deriveRequestedVisibility(dto);
    const requestedModeration = deriveRequestedModeration(dto);

    let nextVisibility = requestedVisibility ?? currentState.visibility;
    let nextModeration = currentState.moderationStatus;

    if (role === UserRole.ADMIN) {
      if (nextVisibility === ContentVisibility.PRIVATE) {
        nextModeration = ContentModerationStatus.NONE;
      } else if (requestedModeration !== undefined) {
        nextModeration = sanitizeAdminModeration(requestedModeration);
      } else if (
        currentState.visibility === ContentVisibility.PRIVATE &&
        nextVisibility === ContentVisibility.PUBLIC
      ) {
        nextModeration = ContentModerationStatus.APPROVED;
      }
    } else {
      const settings = await settingsService.get();
      const publicModeration = settings.autoApproveDocuments
        ? ContentModerationStatus.APPROVED
        : ContentModerationStatus.PENDING;

      if (nextVisibility === ContentVisibility.PRIVATE) {
        nextModeration = ContentModerationStatus.NONE;
      } else if (
        currentState.visibility === ContentVisibility.PRIVATE &&
        nextVisibility === ContentVisibility.PUBLIC
      ) {
        nextModeration = publicModeration;
      } else if (
        hasContentChanges &&
        [
          ContentModerationStatus.APPROVED,
          ContentModerationStatus.REJECTED,
          ContentModerationStatus.HIDDEN,
        ].includes(currentState.moderationStatus)
      ) {
        nextModeration = publicModeration;
      }
    }

    if (
      role !== UserRole.ADMIN &&
      nextVisibility === ContentVisibility.PUBLIC &&
      (hasContentChanges || (currentState.visibility === ContentVisibility.PRIVATE && nextVisibility === ContentVisibility.PUBLIC))
    ) {
      const title = dto.title !== undefined ? dto.title : (item.title ?? '');
      const body = dto.body !== undefined ? (dto.body ?? '') : (item.body ?? '');
      let textToScan = `${title} ${body}`;

      // Lấy fileUrl và fileType từ dữ liệu cập nhật hoặc dữ liệu cũ
      const fileUrl = dto.fileUrl !== undefined ? dto.fileUrl : item.fileUrl;
      const fileType = dto.fileType !== undefined ? dto.fileType : item.fileType;

      if (fileUrl && (fileType === 'pdf' || fileUrl.toLowerCase().includes('.pdf'))) {
        try {
          const pdfText = await extractTextFromPdf(fileUrl);
          if (pdfText) {
            textToScan += ` [PDF Content: ${pdfText}]`;
          }
        } catch (err) {
          logger.error({ fileUrl, err }, 'PDF Extraction Error during Update');
        }
      }

      const modResult = await checkContentModeration(textToScan);
      if (modResult.flagged) {
        nextModeration = ContentModerationStatus.REJECTED;
        updateData.aiRejected = true;
        updateData.rejectionReason = `Tự động từ chối bởi AI. Vi phạm danh mục: ${modResult.categories.join(', ')}`;
      } else if (modResult.error) {
        // Fallback to PENDING if AI moderation fails (e.g. quota limit, api key issue) to prevent auto-approving bad files
        nextModeration = ContentModerationStatus.PENDING;
        updateData.aiRejected = null;
        updateData.rejectionReason = `Lỗi hệ thống khi kiểm duyệt tự động: ${modResult.error}. Cần chờ quản trị viên duyệt thủ công.`;
      } else {
        updateData.aiRejected = null;
        updateData.rejectionReason = null;
      }
    }

    updateData.visibility = nextVisibility;
    updateData.moderationStatus = nextModeration;

    await docRef.update(updateData);
    return documentService.findOne(id, userId, role);
  },

  async remove(id: string, userId: string, role: UserRole) {
    const item = await getDocumentRaw(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    await getDb().collection('documents').doc(id).delete();
    return { success: true };
  },

  async incrementDownload(id: string, viewerId?: string, viewerRole?: UserRole) {
    await documentService.findOne(id, viewerId, viewerRole);

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

    if (viewerId) {
      try {
        await getDb().collection('document_download_logs').add({
          userId: viewerId,
          documentId: id,
          createdAt: new Date(),
        });
      } catch {
        // Non-blocking: weekly stats should not fail downloads.
      }
    }

    return documentService.findOne(id, viewerId, viewerRole);
  },

  async adminHide(id: string, reason: string) {
    const item = await getDocumentRaw(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('documents').doc(id);
    await docRef.update({
      visibility: ContentVisibility.PUBLIC,
      moderationStatus: ContentModerationStatus.HIDDEN,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã bị ẩn`,
      body: `Admin đã ẩn tài liệu của bạn. Lý do: ${reason}`,
    });

    return documentService.findOne(id, item.authorId, UserRole.USER);
  },

  async adminReject(id: string, reason: string) {
    const item = await getDocumentRaw(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('documents').doc(id);
    await docRef.update({
      visibility: ContentVisibility.PUBLIC,
      moderationStatus: ContentModerationStatus.REJECTED,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Tài liệu "${item.title}" bị từ chối duyệt`,
      body: `Admin đã từ chối duyệt tài liệu của bạn. Lý do: ${reason}`,
    });

    return documentService.findOne(id, item.authorId, UserRole.USER);
  },

  async adminDelete(id: string, reason: string) {
    const item = await getDocumentRaw(id);
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
    const item = await getDocumentRaw(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('documents').doc(id);
    await docRef.update({
      visibility: ContentVisibility.PUBLIC,
      moderationStatus: ContentModerationStatus.APPROVED,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã được hiển thị lại`,
      body: note
        ? `Admin đã bỏ ẩn tài liệu của bạn. Ghi chú: ${note}`
        : `Admin đã bỏ ẩn và khôi phục tài liệu của bạn.`,
    });

    return documentService.findOne(id, item.authorId, UserRole.USER);
  },

  async adminApprove(id: string, note?: string) {
    const item = await getDocumentRaw(id);

    const docRef = getDb().collection('documents').doc(id);
    await docRef.update({
      visibility: ContentVisibility.PUBLIC,
      moderationStatus: ContentModerationStatus.APPROVED,
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

    return documentService.findOne(id, item.authorId, UserRole.USER);
  },
};
