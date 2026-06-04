import { getDb } from '../lib/firebase';
import { distanceMeters } from '../lib/geo';
import { HttpError } from '../lib/http-error';
import {
  checkInAllowedRadiusM,
  isWithinCheckInRadius,
  PLACE_CHECKIN_MAX_ACCURACY_M,
} from '../lib/place-checkin-geo';
import { placeService } from './place.service';
import type { CreatePlaceCheckInDto } from '../dto/place-checkin.dto';

const toDate = (val: unknown): Date => {
  if (!val) return new Date();
  if (val instanceof Date) return val;
  if (typeof val === 'object' && val !== null && 'toDate' in val) {
    return (val as { toDate: () => Date }).toDate();
  }
  return new Date(val as string | number);
};

function checkInDocId(placeId: string, userId: string): string {
  return `${placeId}_${userId}`;
}

async function assertPlaceWithCoords(placeId: string): Promise<{
  latitude: number;
  longitude: number;
}> {
  const place = await placeService.findOne(placeId);
  const lat = place.latitude;
  const lng = place.longitude;
  if (typeof lat !== 'number' || typeof lng !== 'number') {
    throw new HttpError(400, 'Địa điểm chưa có tọa độ trên bản đồ', 'Bad Request');
  }
  return { latitude: lat, longitude: lng };
}

export const placeCheckInService = {
  async getStatus(placeId: string, userId?: string) {
    await assertPlaceWithCoords(placeId);

    const snapshot = await getDb()
      .collection('place_checkins')
      .where('placeId', '==', placeId)
      .get();

    const checkInCount = snapshot.size;
    let hasCheckedIn = false;
    let checkedInAt: Date | null = null;

    if (userId) {
      const doc = await getDb()
        .collection('place_checkins')
        .doc(checkInDocId(placeId, userId))
        .get();
      if (doc.exists) {
        hasCheckedIn = true;
        checkedInAt = toDate(doc.data()?.createdAt);
      }
    }

    return { checkInCount, hasCheckedIn, checkedInAt };
  },

  async checkIn(placeId: string, userId: string, dto: CreatePlaceCheckInDto) {
    const coords = await assertPlaceWithCoords(placeId);

    const docId = checkInDocId(placeId, userId);
    const existingRef = getDb().collection('place_checkins').doc(docId);
    const existing = await existingRef.get();
    if (existing.exists) {
      throw new HttpError(
        409,
        'Bạn đã check-in tại địa điểm này rồi',
        'Conflict',
      );
    }

    const dist = distanceMeters(
      dto.latitude,
      dto.longitude,
      coords.latitude,
      coords.longitude,
    );

    if (!isWithinCheckInRadius(dist, dto.accuracy)) {
      const allowed = checkInAllowedRadiusM(dto.accuracy);
      throw new HttpError(
        400,
        `Bạn cần đến gần địa điểm hơn (cách ${Math.round(dist)} m, cho phép tối đa ${Math.round(allowed)} m với độ chính xác GPS hiện tại). Độ chính xác GPS tối đa ${PLACE_CHECKIN_MAX_ACCURACY_M} m.`,
        'Bad Request',
      );
    }

    const now = new Date();
    await existingRef.set({
      placeId,
      userId,
      latitude: dto.latitude,
      longitude: dto.longitude,
      accuracy: dto.accuracy,
      distanceMeters: Math.round(dist),
      createdAt: now,
    });

    const status = await placeCheckInService.getStatus(placeId, userId);
    return {
      checkIn: {
        id: docId,
        placeId,
        userId,
        createdAt: now,
        distanceMeters: Math.round(dist),
      },
      ...status,
    };
  },
};
