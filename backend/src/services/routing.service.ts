import { HttpError } from '../lib/http-error';

const OSRM_BASE = 'https://router.project-osrm.org';
const USER_AGENT = 'Sfinity/1.0';

export interface RouteSummary {
  distanceMeters: number;
  durationSeconds: number;
  profile: string;
  provider: 'osrm';
}

type CacheEntry = { data: RouteSummary; expiresAt: number };

const cache = new Map<string, CacheEntry>();
const CACHE_TTL_MS = 30 * 60 * 1000;

function cacheKey(
  fromLat: number,
  fromLng: number,
  toLat: number,
  toLng: number,
  profile: string,
): string {
  return `${profile}:${fromLat.toFixed(4)},${fromLng.toFixed(4)}->${toLat.toFixed(4)},${toLng.toFixed(4)}`;
}

async function fetchRoute(
  fromLat: number,
  fromLng: number,
  toLat: number,
  toLng: number,
  profile: string,
): Promise<RouteSummary> {
  const coords = `${fromLng},${fromLat};${toLng},${toLat}`;
  const url = `${OSRM_BASE}/route/v1/${profile}/${coords}?overview=false`;

  const response = await fetch(url, {
    headers: { 'User-Agent': USER_AGENT },
  });

  if (!response.ok) {
    throw new HttpError(502, 'Routing service temporarily unavailable', 'Bad Gateway');
  }

  const data = (await response.json()) as {
    code?: string;
    routes?: { distance?: number; duration?: number }[];
  };

  if (data.code !== 'Ok' || !data.routes?.[0]) {
    throw new HttpError(404, 'Không tìm thấy tuyến đường', 'Not Found');
  }

  const route = data.routes[0];
  return {
    distanceMeters: Math.round(route.distance ?? 0),
    durationSeconds: Math.round(route.duration ?? 0),
    profile,
    provider: 'osrm',
  };
}

export const routingService = {
  async getRoute(params: {
    fromLat: number;
    fromLng: number;
    toLat: number;
    toLng: number;
    profile?: 'foot' | 'driving';
  }): Promise<RouteSummary> {
    const { fromLat, fromLng, toLat, toLng } = params;
    if (![fromLat, fromLng, toLat, toLng].every(Number.isFinite)) {
      throw new HttpError(400, 'Tọa độ không hợp lệ', 'Bad Request');
    }

    const profile = params.profile ?? 'foot';
    const key = cacheKey(fromLat, fromLng, toLat, toLng, profile);
    const cached = cache.get(key);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.data;
    }

    const profiles = profile === 'foot' ? ['foot', 'walking'] : [profile];
    let lastError: unknown;
    for (const p of profiles) {
      try {
        const result = await fetchRoute(fromLat, fromLng, toLat, toLng, p);
        cache.set(key, { data: result, expiresAt: Date.now() + CACHE_TTL_MS });
        return result;
      } catch (err) {
        lastError = err;
      }
    }

    if (lastError instanceof HttpError) throw lastError;
    throw new HttpError(502, 'Routing service temporarily unavailable', 'Bad Gateway');
  },
};
