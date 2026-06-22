import { documentService } from './document.service';
import { exploreService } from './explore.service';
import { geocodingService } from './geocoding.service';
import { routingService } from './routing.service';
import { studyNearMeService } from './study-near-me.service';
import { weatherService } from './weather.service';
import { placeService } from './place.service';
import { assistantRagService } from './assistant-rag.service';
import { HttpError } from '../lib/http-error';

export type AssistantSource =
  | 'study-near-me'
  | 'open-meteo'
  | 'osrm'
  | 'nominatim'
  | 'rag'
  | 'places'
  | 'documents'
  | 'explore';

export type AssistantAction =
  | { type: 'open_place'; placeId: string; label?: string }
  | { type: 'open_document'; documentId: string; label?: string }
  | { type: 'open_study_near_me' }
  | { type: 'open_map'; lat: number; lng: number; label?: string };

export interface ToolContext {
  userId: string;
  location?: { lat: number; lng: number };
}

export interface ToolExecutionResult {
  name: string;
  result: unknown;
  sources: AssistantSource[];
  actions: AssistantAction[];
}

function resolveLocation(
  args: Record<string, unknown>,
  ctx: ToolContext,
): { lat: number; lng: number } | null {
  const lat = args.lat != null ? Number(args.lat) : ctx.location?.lat;
  const lng = args.lng != null ? Number(args.lng) : ctx.location?.lng;
  if (typeof lat === 'number' && typeof lng === 'number' && Number.isFinite(lat) && Number.isFinite(lng)) {
    return { lat, lng };
  }
  return null;
}

function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds} giây`;
  const mins = Math.round(seconds / 60);
  if (mins < 60) return `${mins} phút`;
  const hours = Math.floor(mins / 60);
  const rem = mins % 60;
  return rem > 0 ? `${hours} giờ ${rem} phút` : `${hours} giờ`;
}

function formatDistance(meters: number): string {
  if (meters < 1000) return `${meters} m`;
  return `${(meters / 1000).toFixed(1)} km`;
}

function compactPlace(item: any) {
  return {
    id: item.id,
    title: item.title,
    address: item.address ?? null,
    lat: item.latitude ?? null,
    lng: item.longitude ?? null,
    distanceMeters: item.distanceMeters ?? null,
    tags: item.tags ?? [],
  };
}

function compactDocument(item: any) {
  return {
    id: item.id,
    title: item.title,
    subjectCode: item.subjectCode ?? null,
    placeId: item.placeId ?? null,
  };
}

export const GEMINI_TOOL_DECLARATIONS = [
  {
    name: 'find_study_places_nearby',
    description:
      'Tìm địa điểm học tập và tài liệu công khai gần vị trí người dùng (Học gần tôi). Cần lat/lng — dùng vị trí người dùng nếu không truyền.',
    parameters: {
      type: 'OBJECT',
      properties: {
        lat: { type: 'NUMBER', description: 'Vĩ độ GPS' },
        lng: { type: 'NUMBER', description: 'Kinh độ GPS' },
        radiusKm: { type: 'NUMBER', description: 'Bán kính km, mặc định 3' },
        limit: { type: 'INTEGER', description: 'Số kết quả tối đa, mặc định 5' },
      },
    },
  },
  {
    name: 'get_weather',
    description: 'Lấy thời tiết hiện tại tại tọa độ (Open-Meteo). Dùng để gợi ý học trong nhà/ngoài trời.',
    parameters: {
      type: 'OBJECT',
      properties: {
        lat: { type: 'NUMBER' },
        lng: { type: 'NUMBER' },
      },
      required: ['lat', 'lng'],
    },
  },
  {
    name: 'search_places',
    description: 'Tìm địa điểm học tập công khai theo từ khóa, có thể lọc theo vị trí gần.',
    parameters: {
      type: 'OBJECT',
      properties: {
        query: { type: 'STRING', description: 'Từ khóa tìm kiếm' },
        lat: { type: 'NUMBER' },
        lng: { type: 'NUMBER' },
        radiusKm: { type: 'NUMBER' },
        limit: { type: 'INTEGER' },
      },
      required: ['query'],
    },
  },
  {
    name: 'search_documents',
    description: 'Tìm tài liệu học tập công khai theo từ khóa hoặc mã môn.',
    parameters: {
      type: 'OBJECT',
      properties: {
        query: { type: 'STRING' },
        limit: { type: 'INTEGER' },
      },
      required: ['query'],
    },
  },
  {
    name: 'geocode_address',
    description: 'Chuyển địa chỉ hoặc tên khu vực thành tọa độ GPS (Nominatim/OSM). Ví dụ: "Quận 1 TP.HCM".',
    parameters: {
      type: 'OBJECT',
      properties: {
        address: { type: 'STRING' },
      },
      required: ['address'],
    },
  },
  {
    name: 'get_route',
    description: 'Tính thời gian và khoảng cách đi từ A đến B (OSRM). Profile foot = đi bộ, driving = xe máy.',
    parameters: {
      type: 'OBJECT',
      properties: {
        fromLat: { type: 'NUMBER' },
        fromLng: { type: 'NUMBER' },
        toLat: { type: 'NUMBER' },
        toLng: { type: 'NUMBER' },
        profile: { type: 'STRING', description: 'foot hoặc driving' },
      },
      required: ['fromLat', 'fromLng', 'toLat', 'toLng'],
    },
  },
  {
    name: 'get_featured_content',
    description: 'Lấy nội dung nổi bật trên tab Khám phá: địa điểm/tài liệu được quan tâm tuần này.',
    parameters: { type: 'OBJECT', properties: {} },
  },
  {
    name: 'get_app_help',
    description: 'Tra cứu hướng dẫn sử dụng app Sfinity (FAQ nội bộ). Dùng khi hỏi cách thao tác trong app.',
    parameters: {
      type: 'OBJECT',
      properties: {
        query: { type: 'STRING' },
      },
      required: ['query'],
    },
  },
] as const;

export const assistantToolsService = {
  async execute(
    name: string,
    args: Record<string, unknown>,
    ctx: ToolContext,
  ): Promise<ToolExecutionResult> {
    switch (name) {
      case 'find_study_places_nearby':
        return this.findStudyPlacesNearby(args, ctx);
      case 'get_weather':
        return this.getWeather(args, ctx);
      case 'search_places':
        return this.searchPlaces(args, ctx);
      case 'search_documents':
        return this.searchDocuments(args);
      case 'geocode_address':
        return this.geocodeAddress(args);
      case 'get_route':
        return this.getRoute(args, ctx);
      case 'get_featured_content':
        return this.getFeaturedContent();
      case 'get_app_help':
        return this.getAppHelp(args);
      default:
        throw new HttpError(400, `Unknown tool: ${name}`, 'Bad Request');
    }
  },

  async findStudyPlacesNearby(
    args: Record<string, unknown>,
    ctx: ToolContext,
  ): Promise<ToolExecutionResult> {
    const loc = resolveLocation(args, ctx);
    if (!loc) {
      return {
        name: 'find_study_places_nearby',
        result: { error: 'Cần bật GPS hoặc cung cấp lat/lng để tìm gần bạn.' },
        sources: [],
        actions: [{ type: 'open_study_near_me' }],
      };
    }

    const data = await studyNearMeService.findNearby({
      lat: loc.lat,
      lng: loc.lng,
      radiusKm: args.radiusKm != null ? Number(args.radiusKm) : undefined,
      limit: args.limit != null ? Number(args.limit) : 5,
    });

    const places = (data.places as any[]).slice(0, 5).map(compactPlace);
    const documents = (data.documents as any[]).slice(0, 3).map(compactDocument);
    const actions: AssistantAction[] = [{ type: 'open_study_near_me' }];
    for (const p of places.slice(0, 3)) {
      if (p.id) {
        actions.push({ type: 'open_place', placeId: p.id, label: p.title });
      }
    }

    return {
      name: 'find_study_places_nearby',
      result: {
        center: data.center,
        radiusKm: data.radiusKm,
        placeCount: data.placeCount,
        documentCount: data.documentCount,
        places,
        documents,
      },
      sources: ['study-near-me'],
      actions,
    };
  },

  async getWeather(args: Record<string, unknown>, ctx: ToolContext): Promise<ToolExecutionResult> {
    const loc = resolveLocation(args, ctx);
    if (!loc) {
      return {
        name: 'get_weather',
        result: { error: 'Cần tọa độ để xem thời tiết.' },
        sources: [],
        actions: [],
      };
    }

    const weather = await weatherService.getCurrentWeather(loc.lat, loc.lng);
    return {
      name: 'get_weather',
      result: {
        ...weather,
        location: loc,
        summary: `${weather.description}, ${weather.temperatureC}°C, độ ẩm ${weather.humidity}%`,
      },
      sources: ['open-meteo'],
      actions: [],
    };
  },

  async searchPlaces(args: Record<string, unknown>, ctx: ToolContext): Promise<ToolExecutionResult> {
    const query = String(args.query ?? '').trim();
    const loc = resolveLocation(args, ctx);
    const limit = args.limit != null ? Number(args.limit) : 5;

    const result = await placeService.findAll({
      search: query || undefined,
      lat: loc?.lat,
      lng: loc?.lng,
      radiusKm: args.radiusKm != null ? Number(args.radiusKm) : loc ? 10 : undefined,
      publishedOnly: true,
      limit,
      page: 1,
    });

    const places = (result.items as any[]).map(compactPlace);
    const actions: AssistantAction[] = places.slice(0, 3).map((p) => ({
      type: 'open_place' as const,
      placeId: p.id,
      label: p.title,
    }));

    if (places[0]?.lat != null && places[0]?.lng != null) {
      actions.push({
        type: 'open_map',
        lat: places[0].lat,
        lng: places[0].lng,
        label: places[0].title,
      });
    }

    return {
      name: 'search_places',
      result: { query, total: result.total, places },
      sources: ['places'],
      actions,
    };
  },

  async searchDocuments(args: Record<string, unknown>): Promise<ToolExecutionResult> {
    const query = String(args.query ?? '').trim();
    const limit = args.limit != null ? Number(args.limit) : 5;

    const result = await documentService.findAll({
      search: query || undefined,
      publishedOnly: true,
      limit,
      page: 1,
    });

    const documents = (result.items as any[]).map(compactDocument);
    const actions: AssistantAction[] = documents.slice(0, 3).map((d) => ({
      type: 'open_document' as const,
      documentId: d.id,
      label: d.title,
    }));

    return {
      name: 'search_documents',
      result: { query, total: result.total, documents },
      sources: ['documents'],
      actions,
    };
  },

  async geocodeAddress(args: Record<string, unknown>): Promise<ToolExecutionResult> {
    const address = String(args.address ?? '').trim();
    const geo = await geocodingService.geocodeAddress(address);

    return {
      name: 'geocode_address',
      result: geo,
      sources: ['nominatim'],
      actions: [{ type: 'open_map', lat: geo.lat, lng: geo.lng, label: geo.displayName }],
    };
  },

  async getRoute(args: Record<string, unknown>, ctx: ToolContext): Promise<ToolExecutionResult> {
    const fromLat = args.fromLat != null ? Number(args.fromLat) : ctx.location?.lat;
    const fromLng = args.fromLng != null ? Number(args.fromLng) : ctx.location?.lng;
    const toLat = args.toLat != null ? Number(args.toLat) : NaN;
    const toLng = args.toLng != null ? Number(args.toLng) : NaN;

    if (!Number.isFinite(fromLat) || !Number.isFinite(fromLng)) {
      return {
        name: 'get_route',
        result: { error: 'Cần vị trí xuất phát (GPS người dùng).' },
        sources: [],
        actions: [],
      };
    }

    const profile = args.profile === 'driving' ? 'driving' : 'foot';
    const route = await routingService.getRoute({
      fromLat: fromLat as number,
      fromLng: fromLng as number,
      toLat,
      toLng,
      profile,
    });

    return {
      name: 'get_route',
      result: {
        ...route,
        summary: `${formatDistance(route.distanceMeters)}, khoảng ${formatDuration(route.durationSeconds)} (${profile === 'foot' ? 'đi bộ' : 'xe máy'})`,
      },
      sources: ['osrm'],
      actions:
        Number.isFinite(toLat) && Number.isFinite(toLng)
          ? [{ type: 'open_map', lat: toLat, lng: toLng }]
          : [],
    };
  },

  async getFeaturedContent(): Promise<ToolExecutionResult> {
    const featured = await exploreService.getFeatured();
    const places = ((featured as any).trendingPlaces ?? []).slice(0, 3).map(compactPlace);
    const documents = ((featured as any).trendingDocuments ?? []).slice(0, 3).map(compactDocument);

    const actions: AssistantAction[] = [
      ...places.map((p: ReturnType<typeof compactPlace>) => ({
        type: 'open_place' as const,
        placeId: p.id,
        label: p.title,
      })),
      ...documents.map((d: ReturnType<typeof compactDocument>) => ({
        type: 'open_document' as const,
        documentId: d.id,
        label: d.title,
      })),
    ];

    return {
      name: 'get_featured_content',
      result: { places, documents },
      sources: ['explore'],
      actions,
    };
  },

  async getAppHelp(args: Record<string, unknown>): Promise<ToolExecutionResult> {
    const query = String(args.query ?? '').trim();
    const { chunks, chunkIds } = assistantRagService.retrieve(query, 3);

    return {
      name: 'get_app_help',
      result: { query, chunks, chunkIds },
      sources: ['rag'],
      actions: [],
    };
  },
};
