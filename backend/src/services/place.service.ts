import { itemHasAllTags, parseTagsQuery } from '../constants/place-tags';
import { isValidPlaceZone } from '../constants/place-zones';
import {
  applyContentState,
  deriveRequestedModeration,
  deriveRequestedVisibility,
  isPubliclyVisible,
  normalizeContentState,
  sanitizeAdminModeration,
} from '../lib/content-state';
import { getDb } from '../lib/firebase';
import { distanceMeters } from '../lib/geo';
import { HttpError } from '../lib/http-error';
import { checkContentModeration } from '../lib/moderation';
import { notificationsService } from './notifications.service';
import { settingsService } from './settings.service';
import {
  ContentModerationStatus,
  ContentVisibility,
  UserRole,
} from '../types/enums';
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

async function enrichPlace(item: any) {
  const normalized = applyContentState(item);

  let author = null;
  if (normalized.authorId) {
    const authorDoc = await getDb().collection('users').doc(normalized.authorId).get();
    if (authorDoc.exists) {
      const a = authorDoc.data() as any;
      author = { id: authorDoc.id, name: a.name, email: a.email };
    }
  }

  return {
    ...normalized,
    id: normalized.id,
    type: 'place',
    createdAt: toDate(normalized.createdAt),
    updatedAt: toDate(normalized.updatedAt),
    author,
  };
}

async function getPlaceRaw(id: string) {
  const doc = await getDb().collection('places').doc(id).get();
  if (!doc.exists) {
    throw new HttpError(404, 'Không tìm thấy địa điểm', 'Not Found');
  }
  return { id: doc.id, ...doc.data() } as any;
}

type PlaceRatingStats = { avgRating: number; reviewCount: number };

async function loadPlaceRatingMap(): Promise<Map<string, PlaceRatingStats>> {
  const snapshot = await getDb().collection('place_reviews').get();
  const ratingsByPlace = new Map<string, number[]>();

  for (const doc of snapshot.docs) {
    const data = doc.data() as { placeId?: string; rating?: number };
    const placeId = data.placeId;
    const rating = data.rating;
    if (typeof placeId !== 'string' || typeof rating !== 'number' || rating < 1 || rating > 5) {
      continue;
    }
    const list = ratingsByPlace.get(placeId) ?? [];
    list.push(rating);
    ratingsByPlace.set(placeId, list);
  }

  const result = new Map<string, PlaceRatingStats>();
  for (const [placeId, ratings] of ratingsByPlace) {
    const reviewCount = ratings.length;
    const avgRating =
      Math.round((ratings.reduce((sum, value) => sum + value, 0) / reviewCount) * 10) / 10;
    result.set(placeId, { avgRating, reviewCount });
  }
  return result;
}

function attachRatingStats(
  items: any[],
  ratingMap: Map<string, PlaceRatingStats>,
): any[] {
  return items.map((item) => {
    const stats = ratingMap.get(item.id);
    if (!stats) return item;
    return { ...item, avgRating: stats.avgRating, reviewCount: stats.reviewCount };
  });
}

function isOwnerOrAdmin(item: any, viewerId?: string, viewerRole?: UserRole): boolean {
  return viewerRole === UserRole.ADMIN || (!!viewerId && item.authorId === viewerId);
}

function canViewPlace(item: any, viewerId?: string, viewerRole?: UserRole): boolean {
  return isOwnerOrAdmin(item, viewerId, viewerRole) || isPubliclyVisible(item);
}

export const placeService = {
  async findAll(params: {
    search?: string;
    visibility?: ContentVisibility;
    moderationStatus?: ContentModerationStatus;
    authorId?: string;
    tags?: string;
    zone?: string;
    lat?: number;
    lng?: number;
    radiusKm?: number;
    minRating?: number;
    page?: number;
    limit?: number;
    publishedOnly?: boolean;
    viewerId?: string;
    viewerRole?: UserRole;
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

    if (params.visibility) {
      items = items.filter((item) => item.visibility === params.visibility);
    }

    if (params.moderationStatus) {
      items = items.filter((item) => item.moderationStatus === params.moderationStatus);
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

    const ratingMap = await loadPlaceRatingMap();
    items = attachRatingStats(items, ratingMap);

    if (params.minRating != null && params.minRating > 0) {
      items = items.filter((item) => {
        const stats = ratingMap.get(item.id);
        return stats != null && stats.avgRating >= params.minRating!;
      });
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
    const resolvedItems = await Promise.all(paginatedItems.map((item) => enrichPlace(item)));

    return { items: resolvedItems, total, page, limit, totalPages: Math.ceil(total / limit) };
  },

  async findOne(id: string, viewerId?: string, viewerRole?: UserRole) {
    const item = await getPlaceRaw(id);
    if (!canViewPlace(item, viewerId, viewerRole)) {
      throw new HttpError(404, 'Không tìm thấy địa điểm', 'Not Found');
    }
    return enrichPlace(item);
  },

  async create(authorId: string, dto: CreatePlaceDto, role: UserRole = UserRole.USER) {
    const docRef = getDb().collection('places').doc();

    if (dto.zone != null && !isValidPlaceZone(dto.zone)) {
      throw new HttpError(400, 'Khu vực không hợp lệ', 'Bad Request');
    }

    const requestedVisibility = deriveRequestedVisibility(dto) ?? ContentVisibility.PUBLIC;
    const settings = role === UserRole.ADMIN ? null : await settingsService.get();
    const autoApprove = settings?.autoApprovePlaces ?? false;

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
      const textToScan = `${dto.title} ${dto.body ?? ''} ${dto.address ?? ''}`;
      const modResult = await checkContentModeration(textToScan);
      if (modResult.flagged) {
        moderationStatus = ContentModerationStatus.REJECTED;
        aiRejected = true;
        rejectionReason = `Tự động từ chối bởi AI. Vi phạm danh mục: ${modResult.categories.join(', ')}`;
      } else if (modResult.error) {
        moderationStatus = ContentModerationStatus.PENDING;
        rejectionReason = `Lỗi hệ thống khi kiểm duyệt tự động: ${modResult.error}. Cần chờ quản trị viên duyệt thủ công.`;
      } else {
        moderationStatus = ContentModerationStatus.APPROVED;
      }
    }

    const newPlace: any = {
      id: docRef.id,
      title: dto.title,
      body: dto.body ?? '',
      visibility: state.visibility,
      moderationStatus,
      aiRejected,
      rejectionReason,
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
    return placeService.findOne(docRef.id, authorId, role);
  },

  async update(id: string, dto: UpdatePlaceDto, userId: string, role: UserRole) {
    const item = await getPlaceRaw(id);
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
    const currentState = normalizeContentState(item);

    let hasContentChanges = false;
    for (const [key, value] of Object.entries(dto)) {
      if (value !== undefined) {
        updateData[key] = value;
        if (['title', 'body', 'latitude', 'longitude', 'address', 'zone', 'tags'].includes(key)) {
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
      const publicModeration = settings.autoApprovePlaces
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
      const address = dto.address !== undefined ? (dto.address ?? '') : (item.address ?? '');
      const textToScan = `${title} ${body} ${address}`;

      const modResult = await checkContentModeration(textToScan);
      if (modResult.flagged) {
        nextModeration = ContentModerationStatus.REJECTED;
        updateData.aiRejected = true;
        updateData.rejectionReason = `Tự động từ chối bởi AI. Vi phạm danh mục: ${modResult.categories.join(', ')}`;
      } else if (modResult.error) {
        nextModeration = ContentModerationStatus.PENDING;
        updateData.aiRejected = null;
        updateData.rejectionReason = `Lỗi hệ thống khi kiểm duyệt tự động: ${modResult.error}. Cần chờ quản trị viên duyệt thủ công.`;
      } else {
        nextModeration = ContentModerationStatus.APPROVED;
        updateData.aiRejected = null;
        updateData.rejectionReason = null;
      }
    }

    updateData.visibility = nextVisibility;
    updateData.moderationStatus = nextModeration;

    await docRef.update(updateData);
    return placeService.findOne(id, userId, role);
  },

  async remove(id: string, userId: string, role: UserRole) {
    const item = await getPlaceRaw(id);
    if (role !== UserRole.ADMIN && item.authorId !== userId) {
      throw new HttpError(404, 'Not Found', 'Not Found');
    }

    await getDb().collection('places').doc(id).delete();
    return { success: true };
  },

  async adminHide(id: string, reason: string) {
    const item = await getPlaceRaw(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('places').doc(id);
    await docRef.update({
      visibility: ContentVisibility.PUBLIC,
      moderationStatus: ContentModerationStatus.HIDDEN,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã bị ẩn`,
      body: `Admin đã ẩn địa điểm của bạn. Lý do: ${reason}`,
    });

    return placeService.findOne(id, item.authorId, UserRole.USER);
  },

  async adminReject(id: string, reason: string) {
    const item = await getPlaceRaw(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('places').doc(id);
    await docRef.update({
      visibility: ContentVisibility.PUBLIC,
      moderationStatus: ContentModerationStatus.REJECTED,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Địa điểm "${item.title}" bị từ chối duyệt`,
      body: `Admin đã từ chối duyệt địa điểm của bạn. Lý do: ${reason}`,
    });

    return placeService.findOne(id, item.authorId, UserRole.USER);
  },

  async adminDelete(id: string, reason: string) {
    const item = await getPlaceRaw(id);
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
    const item = await getPlaceRaw(id);
    if (!item.authorId) {
      throw new HttpError(400, 'Không tìm thấy tác giả để gửi thông báo', 'Bad Request');
    }

    const docRef = getDb().collection('places').doc(id);
    await docRef.update({
      visibility: ContentVisibility.PUBLIC,
      moderationStatus: ContentModerationStatus.APPROVED,
      updatedAt: new Date(),
    });

    await notificationsService.create({
      userId: item.authorId,
      title: `Nội dung "${item.title}" đã được hiển thị lại`,
      body: note
        ? `Admin đã bỏ ẩn địa điểm của bạn. Ghi chú: ${note}`
        : `Admin đã bỏ ẩn và khôi phục địa điểm của bạn.`,
    });

    return placeService.findOne(id, item.authorId, UserRole.USER);
  },

  async adminApprove(id: string, note?: string) {
    const item = await getPlaceRaw(id);

    const docRef = getDb().collection('places').doc(id);
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
          ? `Địa điểm của bạn đã được admin duyệt và xuất bản. Ghi chú: ${note}`
          : `Địa điểm của bạn đã được admin duyệt và xuất bản.`,
      });
    }

    return placeService.findOne(id, item.authorId, UserRole.USER);
  },
};
