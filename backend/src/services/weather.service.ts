import { HttpError } from '../lib/http-error';

export interface PlaceWeatherResult {
  temperatureC: number;
  humidity: number;
  description: string;
  provider: 'open-meteo' | 'openweather';
}

type CacheEntry = { data: PlaceWeatherResult; expiresAt: number };

const cache = new Map<string, CacheEntry>();
const CACHE_TTL_MS = 45 * 60 * 1000;

function cacheKey(lat: number, lng: number): string {
  return `${lat.toFixed(3)},${lng.toFixed(3)}`;
}

function describeWmoCode(code: number): string {
  if (code === 0) return 'Trời quang';
  if (code <= 3) return 'Có mây';
  if (code <= 48) return 'Sương mù';
  if (code <= 57) return 'Mưa phùn';
  if (code <= 67) return 'Mưa';
  if (code <= 77) return 'Tuyết';
  if (code <= 82) return 'Mưa rào';
  if (code <= 86) return 'Mưa đá';
  if (code <= 99) return 'Dông';
  return 'Không xác định';
}

async function fetchOpenMeteo(lat: number, lng: number): Promise<PlaceWeatherResult> {
  const url = new URL('https://api.open-meteo.com/v1/forecast');
  url.searchParams.set('latitude', String(lat));
  url.searchParams.set('longitude', String(lng));
  url.searchParams.set('current', 'temperature_2m,relative_humidity_2m,weather_code');
  url.searchParams.set('timezone', 'Asia/Ho_Chi_Minh');

  const response = await fetch(url.toString());
  if (!response.ok) {
    throw new HttpError(502, 'Weather service temporarily unavailable', 'Bad Gateway');
  }

  const data = (await response.json()) as {
    current?: {
      temperature_2m?: number;
      relative_humidity_2m?: number;
      weather_code?: number;
    };
  };

  const current = data.current;
  const temperatureC = current?.temperature_2m;
  if (typeof temperatureC !== 'number') {
    throw new HttpError(502, 'Invalid weather response', 'Bad Gateway');
  }

  const code = current?.weather_code ?? -1;
  return {
    temperatureC: Math.round(temperatureC * 10) / 10,
    humidity: Math.round(current?.relative_humidity_2m ?? 0),
    description: describeWmoCode(code),
    provider: 'open-meteo',
  };
}

export const weatherService = {
  async getCurrentWeather(lat: number, lng: number): Promise<PlaceWeatherResult> {
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      throw new HttpError(400, 'Invalid coordinates', 'Bad Request');
    }

    const key = cacheKey(lat, lng);
    const cached = cache.get(key);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.data;
    }

    const data = await fetchOpenMeteo(lat, lng);
    cache.set(key, { data, expiresAt: Date.now() + CACHE_TTL_MS });
    return data;
  },
};
