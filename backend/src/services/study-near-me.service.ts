import { documentService } from './document.service';

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

    const placesResult = await documentService.findAll({
      type: 'place',
      lat: params.lat,
      lng: params.lng,
      radiusKm,
      publishedOnly: true,
      limit,
    });

    const placeIds = new Set(
      placesResult.items.map((p: { id: string }) => p.id).filter(Boolean),
    );

    const documentsResult = await documentService.findAll({
      type: 'document',
      lat: params.lat,
      lng: params.lng,
      radiusKm,
      publishedOnly: true,
      limit: limit * 2,
    });

    let documents = documentsResult.items as any[];

    if (placeIds.size > 0) {
      const linkedResult = await documentService.findAll({
        type: 'document',
        publishedOnly: true,
        limit: limit * 2,
      });
      const linkedByPlace = (linkedResult.items as any[]).filter(
        (doc) => doc.placeId && placeIds.has(doc.placeId),
      );
      const seen = new Set(documents.map((d) => d.id));
      for (const doc of linkedByPlace) {
        if (!seen.has(doc.id)) {
          documents.push(doc);
          seen.add(doc.id);
        }
      }
    }

    documents = documents.slice(0, limit);

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
