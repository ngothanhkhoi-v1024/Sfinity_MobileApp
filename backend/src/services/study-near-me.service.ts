import { documentService } from './document.service';
import { placeService } from './place.service';

/** Bán kính mặc định "Học gần tôi" (km). */
export const STUDY_NEAR_ME_DEFAULT_RADIUS_KM = 3;

export const studyNearMeService = {
  async findNearby(params: {
    lat: number;
    lng: number;
    radiusKm?: number;
    limit?: number;
  }) {
    const radiusKm = params.radiusKm ?? STUDY_NEAR_ME_DEFAULT_RADIUS_KM;
    const limit = params.limit ?? 30;

    const placesResult = await placeService.findAll({
      lat: params.lat,
      lng: params.lng,
      radiusKm,
      publishedOnly: true,
      limit,
    });

    const placeIds = new Set(
      placesResult.items.map((p: { id: string }) => p.id).filter(Boolean),
    );

    let documents: any[] = [];

    if (placeIds.size > 0) {
      const linkedResult = await documentService.findAll({
        publishedOnly: true,
        limit: limit * 4,
      });
      const linkedByPlace = (linkedResult.items as any[]).filter(
        (doc) => doc.placeId && placeIds.has(doc.placeId),
      );
      documents = linkedByPlace.slice(0, limit);
    }

    return {
      center: { lat: params.lat, lng: params.lng },
      radiusKm,
      places: placesResult.items,
      documents,
      placeCount: placesResult.total,
      documentCount: documents.length,
    };
  },
};
