const NOMINATIM_BASE = 'https://nominatim.openstreetmap.org';

const geocodeCache = new Map<string, Promise<string | null>>();

export async function reverseGeocode(lat: number, lng: number): Promise<string | null> {
  const key = `${lat.toFixed(5)},${lng.toFixed(5)}`;
  if (!geocodeCache.has(key)) {
    geocodeCache.set(
      key,
      (async () => {
        try {
          const res = await fetch(
            `${NOMINATIM_BASE}/reverse?lat=${lat}&lon=${lng}&format=json&addressdetails=1`,
            { headers: { 'Accept-Language': 'vi' } },
          );
          if (!res.ok) return null;
          const data = (await res.json()) as { display_name?: string };
          return data.display_name ?? null;
        } catch {
          return null;
        }
      })(),
    );
  }
  return geocodeCache.get(key) ?? null;
}
