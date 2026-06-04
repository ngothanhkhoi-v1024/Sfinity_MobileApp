import { itemHasAllTags, parseTagsQuery } from '../constants/place-tags';
import { isValidPlaceZone } from '../constants/place-zones';
import { getDb } from '../lib/firebase';
import { distanceMeters } from '../lib/geo';
import { HttpError } from '../lib/http-error';
import { notificationsService } from './notifications.service';
import { settingsService } from './settings.service';
import { ContentStatus, UserRole } from '../types/enums';
import type { CreateDocumentDto, UpdateDocumentDto } from '../dto/document.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

const legacyPlaceIdInBody = (body: unknown, placeId: string): boolean => {
  const text = typeof body === 'string' ? body : '';
  return text.includes(`placeId:${placeId}`);
};

const itemMatchesPlaceId = (item: any, placeId: string): boolean =>
  item.placeId === placeId || legacyPlaceIdInBody(item.body, placeId);

const extractCoords = (item: any): { lat: number; lng: number } | null => {
  const lat = item.latitude;
  const lng = item.longitude;
  if (typeof lat === 'number' && typeof lng === 'number') {
    return { lat, lng };
  }
  const body = typeof item.body === 'string' ? item.body : '';
  if (body.includes('type:place')) {
    const latMatch = /lat:\s*([-\d.]+)/.exec(body);
    const lngMatch = /lng:\s*([-\d.]+)/.exec(body);
    if (latMatch && lngMatch) {
      const parsedLat = Number(latMatch[1]);
      const parsedLng = Number(lngMatch[1]);
      if (Number.isFinite(parsedLat) && Number.isFinite(parsedLng)) {
        return { lat: parsedLat, lng: parsedLng };
      }
    }
  }
  return null;
};

async function assertPlaceOwnerForDocument(
  placeId: string,
  userId: string,
  role: UserRole,
): Promise<void> {
  const place = await documentService.findOne(placeId);
  if ((place.type ?? 'document') !== 'place') {
    throw new HttpError(400, 'placeId không hợp lệ', 'Bad Request');
  }
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
    type?: string;
    authorId?: string;
    placeId?: string;
    tags?: string;
    zone?: string;
    lat?: number;
    lng?: number;
    radiusKm?: number;
    page?: number;
    limit?: number;
    publishedOnly?: boolean;
  }) {
    const page = params.page ?? 1;
    const limit = params.limit ?? 20;
    const skip = (page - 1) * limit;
    const hasGeo =
      typeof params.lat === 'number' &&
      typeof params.lng === 'number' &&
      Number.isFinite(params.lat) &&
      Number.isFinite(params.lng);
    const radiusM =
      hasGeo && params.radiusKm != null && params.radiusKm > 0
        ? params.radiusKm * 1000
        : null;

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

    if (params.type) {
      items = items.filter((item) => (item.type ?? 'document') === params.type);
    }

    if (params.authorId) {
      items = items.filter((item) => item.authorId === params.authorId);
    }

    if (params.placeId) {
      items = items.filter((item) => itemMatchesPlaceId(item, params.placeId!));
    }

    const requiredTags = parseTagsQuery(params.tags);
    if (requiredTags.length > 0) {
      items = items.filter((item) => itemHasAllTags(item, requiredTags));
    }

    if (params.zone) {
      items = items.filter((item) => item.zone === params.zone);
    }

    if (params.search) {
      const term = params.search.toLowerCase();
      items = items.filter(
        (item) =>
          (item.title && item.title.toLowerCase().includes(term)) ||
          (item.body && item.body.toLowerCase().includes(term)) ||
          (item.address && String(item.address).toLowerCase().includes(term)),
      );
    }

    if (hasGeo && radiusM != null) {
      items = items
        .map((item) => {
          const coords = extractCoords(item);
          if (!coords) return null;
          const dist = distanceMeters(params.lat!, params.lng!, coords.lat, coords.lng);
          if (dist > radiusM) return null;
          return { ...item, distanceMeters: Math.round(dist) };
        })
        .filter(Boolean) as any[];
      items.sort((a, b) => (a.distanceMeters ?? 0) - (b.distanceMeters ?? 0));
    } else {
      items.sort((a, b) => toDate(b.createdAt).getTime() - toDate(a.createdAt).getTime());
    }

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
      categoryId: item.categoryId ?? null,
      createdAt: toDate(item.createdAt),
      updatedAt: toDate(item.updatedAt),
      author,
      category,
    };
  },

  async create(authorId: string, dto: CreateDocumentDto, role: UserRole = UserRole.USER) {
    const docRef = getDb().collection('documents').doc();
    const type = dto.type ?? 'document';

    if (type === 'document' && dto.placeId) {
      await assertPlaceOwnerForDocument(dto.placeId, authorId, role);
    }

    let initialStatus = dto.status ?? ContentStatus.PENDING;
    if (role !== UserRole.ADMIN) {
      if (initialStatus === ContentStatus.PUBLISHED || initialStatus === ContentStatus.REJECTED || initialStatus === ContentStatus.HIDDEN) {
        initialStatus = ContentStatus.PENDING;
      }
      const settings = await settingsService.get();
      const autoApprove = type === 'place' ? settings.autoApprovePlaces : settings.autoApproveDocuments;
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
      if (dto.placeId) {
        newDocument.placeId = dto.placeId;
      }
    } else if (type === 'place') {
      if (dto.zone != null && !isValidPlaceZone(dto.zone)) {
        throw new HttpError(400, 'Khu vực không hợp lệ', 'Bad Request');
      }
      newDocument.latitude = dto.latitude ?? null;
      newDocument.longitude = dto.longitude ?? null;
      newDocument.address = dto.address ?? null;
      newDocument.zone = dto.zone ?? null;
      newDocument.tags = dto.tags ?? [];
    }

    await docRef.set(newDocument);
    return documentService.findOne(docRef.id);
  },

  async update(id: string, dto: UpdateDocumentDto, userId: string, role: UserRole) {
    const item = await documentService.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    const docType = item.type ?? 'document';
    if (docType === 'document' && dto.placeId) {
      await assertPlaceOwnerForDocument(dto.placeId, userId, role);
    }
    if (docType === 'place' && dto.zone != null && !isValidPlaceZone(dto.zone)) {
      throw new HttpError(400, 'Khu vực không hợp lệ', 'Bad Request');
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
        const autoApprove = docType === 'place' ? settings.autoApprovePlaces : settings.autoApproveDocuments;
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

    const typeLabel = (item.type ?? 'document') === 'place' ? 'địa điểm' : 'tài liệu';
    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã bị ẩn`,
      body: `Admin đã ẩn ${typeLabel} của bạn. Lý do: ${reason}`,
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

    const typeLabel = (item.type ?? 'document') === 'place' ? 'địa điểm' : 'tài liệu';
    await notificationsService.create({
      userId: item.authorId,
      title: `Tài liệu "${item.title}" bị từ chối duyệt`,
      body: `Admin đã từ chối duyệt ${typeLabel} của bạn. Lý do: ${reason}`,
    });

    return documentService.findOne(id);
  },

  async adminDelete(id: string, reason: string) {
    const item = await documentService.findOne(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const typeLabel = (item.type ?? 'document') === 'place' ? 'địa điểm' : 'tài liệu';
    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã bị xóa`,
      body: `Admin đã xóa ${typeLabel} của bạn. Lý do: ${reason}`,
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

    const typeLabel = (item.type ?? 'document') === 'place' ? 'địa điểm' : 'tài liệu';
    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã được hiển thị lại`,
      body: note
        ? `Admin đã bỏ ẩn ${typeLabel} của bạn. Ghi chú: ${note}`
        : `Admin đã bỏ ẩn và khôi phục ${typeLabel} của bạn.`,
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
      const typeLabel = (item.type ?? 'document') === 'place' ? 'địa điểm' : 'tài liệu';
      await notificationsService.create({
        userId: item.authorId,
        title: `Nội dung "${item.title}" đã được duyệt`,
        body: note
          ? `${typeLabel.charAt(0).toUpperCase() + typeLabel.slice(1)} của bạn đã được admin duyệt và xuất bản. Ghi chú: ${note}`
          : `${typeLabel.charAt(0).toUpperCase() + typeLabel.slice(1)} của bạn đã được admin duyệt và xuất bản.`,
      });
    }

    return documentService.findOne(id);
  },
};
