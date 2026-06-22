import { HttpError } from '../lib/http-error';

export interface GeocodeResult {
  lat: number;
  lng: number;
  displayName: string;
  provider: 'nominatim';
}

type CacheEntry = { data: GeocodeResult; expiresAt: number };

const cache = new Map<string, CacheEntry>();
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const USER_AGENT = 'Sfinity/1.0 (study places app; contact: admin@sfinity.com)';

function normalizeAddress(address: string): string {
  return address.trim().toLowerCase();
}

export const geocodingService = {
  async geocodeAddress(address: string): Promise<GeocodeResult> {
    const trimmed = address.trim();
    if (trimmed.length < 2) {
      throw new HttpError(400, 'Địa chỉ quá ngắn', 'Bad Request');
    }

    const key = normalizeAddress(trimmed);
    const cached = cache.get(key);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.data;
    }

    const url = new URL('https://nominatim.openstreetmap.org/search');
    url.searchParams.set('q', trimmed);
    url.searchParams.set('format', 'json');
    url.searchParams.set('limit', '1');
    url.searchParams.set('countrycodes', 'vn');

    const response = await fetch(url.toString(), {
      headers: { 'User-Agent': USER_AGENT, Accept: 'application/json' },
    });

    if (!response.ok) {
      throw new HttpError(502, 'Geocoding service temporarily unavailable', 'Bad Gateway');
    }

    const data = (await response.json()) as { lat?: string; lon?: string; display_name?: string }[];
    const first = data[0];
    const lat = first?.lat != null ? Number(first.lat) : NaN;
    const lng = first?.lon != null ? Number(first.lon) : NaN;

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      throw new HttpError(404, 'Không tìm thấy địa chỉ', 'Not Found');
    }

    const result: GeocodeResult = {
      lat,
      lng,
      displayName: first.display_name ?? trimmed,
      provider: 'nominatim',
    };

    cache.set(key, { data: result, expiresAt: Date.now() + CACHE_TTL_MS });
    return result;
  },
};
