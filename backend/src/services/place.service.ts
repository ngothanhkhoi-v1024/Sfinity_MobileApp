import { itemHasAllTags, parseTagsQuery } from '../constants/place-tags';
import { isValidPlaceZone } from '../constants/place-zones';
import { getDb } from '../lib/firebase';
import { distanceMeters } from '../lib/geo';
import { HttpError } from '../lib/http-error';
import { notificationsService } from './notifications.service';
import { settingsService } from './settings.service';
import { ContentStatus, UserRole } from '../types/enums';
import type { CreatePlaceDto, UpdatePlaceDto } from '../dto/place.dto';

const toDate = (val: any): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  return new Date(val);
};

const extractCoords = (item: any): { lat: number; lng: number } | null => {
  const lat = item.latitude;
  const lng = item.longitude;
  if (typeof lat === 'number' && typeof lng === 'number') {
    return { lat, lng };
  }
  return null;
};

export const placeService = {
  async findAll(params: {
    search?: string;
    status?: ContentStatus;
    authorId?: string;
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

    const snapshot = await getDb().collection('places').get();
    let items = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as any));

    if (params.publishedOnly) {
      items = items.filter((item) => item.status === ContentStatus.PUBLISHED);
    } else if (params.status) {
      items = items.filter((item) => item.status === params.status);
    }

    if (params.authorId) {
      items = items.filter((item) => item.authorId === params.authorId);
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

        return {
          ...item,
          id: item.id,
          type: 'place', // Inject type for compatibility
          createdAt: toDate(item.createdAt),
          updatedAt: toDate(item.updatedAt),
          author,
        };
      }),
    );

    return { items: resolvedItems, total, page, limit, totalPages: Math.ceil(total / limit) };
  },

  async findOne(id: string) {
    const doc = await getDb().collection('places').doc(id).get();
    if (!doc.exists) {
      throw new HttpError(404, 'Không tìm thấy địa điểm', 'Not Found');
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

    return {
      ...item,
      id: item.id,
      type: 'place', // Inject type for compatibility
      createdAt: toDate(item.createdAt),
      updatedAt: toDate(item.updatedAt),
      author,
    };
  },

  async create(authorId: string, dto: CreatePlaceDto, role: UserRole = UserRole.USER) {
    const docRef = getDb().collection('places').doc();

    let initialStatus = dto.status ?? ContentStatus.PENDING;
    if (role !== UserRole.ADMIN) {
      if (initialStatus === ContentStatus.PUBLISHED || initialStatus === ContentStatus.REJECTED || initialStatus === ContentStatus.HIDDEN) {
        initialStatus = ContentStatus.PENDING;
      }
      const settings = await settingsService.get();
      if ((initialStatus === ContentStatus.PENDING || initialStatus === ContentStatus.DRAFT) && settings.autoApprovePlaces) {
        initialStatus = ContentStatus.PUBLISHED;
      }
    }

    if (dto.zone != null && !isValidPlaceZone(dto.zone)) {
      throw new HttpError(400, 'Khu vực không hợp lệ', 'Bad Request');
    }

    const newPlace: any = {
      id: docRef.id,
      title: dto.title,
      body: dto.body ?? '',
      status: initialStatus,
      authorId,
      latitude: dto.latitude,
      longitude: dto.longitude,
      address: dto.address ?? null,
      zone: dto.zone ?? null,
      tags: dto.tags ?? [],
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await docRef.set(newPlace);
    return placeService.findOne(docRef.id);
  },

  async update(id: string, dto: UpdatePlaceDto, userId: string, role: UserRole) {
    const item = await placeService.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    if (dto.zone != null && !isValidPlaceZone(dto.zone)) {
      throw new HttpError(400, 'Khu vực không hợp lệ', 'Bad Request');
    }

    const docRef = getDb().collection('places').doc(id);
    const updateData: any = {
      updatedAt: new Date(),
    };

    let hasContentChanges = false;
    for (const [key, value] of Object.entries(dto)) {
      if (value !== undefined) {
        updateData[key] = value;
        if (['title', 'body', 'latitude', 'longitude', 'address', 'zone', 'tags'].includes(key)) {
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
        if (settings.autoApprovePlaces) {
          updateData.status = ContentStatus.PUBLISHED;
        }
      }
    }

    await docRef.update(updateData);
    return placeService.findOne(id);
  },

  async remove(id: string, userId: string, role: UserRole) {
    const item = await placeService.findOne(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    await getDb().collection('places').doc(id).delete();
    return { success: true };
  },

  async adminHide(id: string, reason: string) {
    const item = await placeService.findOne(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('places').doc(id);
    await docRef.update({
      status: ContentStatus.HIDDEN,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã bị ẩn`,
      body: `Admin đã ẩn địa điểm của bạn. Lý do: ${reason}`,
    });

    return placeService.findOne(id);
  },

  async adminReject(id: string, reason: string) {
    const item = await placeService.findOne(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('places').doc(id);
    await docRef.update({
      status: ContentStatus.REJECTED,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Địa điểm "${item.title}" bị từ chối duyệt`,
      body: `Admin đã từ chối duyệt địa điểm của bạn. Lý do: ${reason}`,
    });

    return placeService.findOne(id);
  },

  async adminDelete(id: string, reason: string) {
    const item = await placeService.findOne(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã bị xóa`,
      body: `Admin đã xóa địa điểm của bạn. Lý do: ${reason}`,
    });

    await getDb().collection('places').doc(id).delete();
    return { success: true };
  },

  async adminUnhide(id: string, note?: string) {
    const item = await placeService.findOne(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('places').doc(id);
    await docRef.update({
      status: ContentStatus.PUBLISHED,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã được hiển thị lại`,
      body: note
        ? `Admin đã bỏ ẩn địa điểm của bạn. Ghi chú: ${note}`
        : `Admin đã bỏ ẩn và khôi phục địa điểm của bạn.`,
    });

    return placeService.findOne(id);
  },

  async adminApprove(id: string, note?: string) {
    const item = await placeService.findOne(id);

    const docRef = getDb().collection('places').doc(id);
    await docRef.update({
      status: ContentStatus.PUBLISHED,
      updatedAt: new Date(),
    });

    if (item.authorId) {
      await notificationsService.create({
        userId: item.authorId,
        title: `Nội dung "${item.title}" đã được duyệt`,
        body: note
          ? `Địa điểm của bạn đã được admin duyệt và xuất bản. Ghi chú: ${note}`
          : `Địa điểm của bạn đã được admin duyệt và xuất bản.`,
      });
    }

    return placeService.findOne(id);
  },
};
