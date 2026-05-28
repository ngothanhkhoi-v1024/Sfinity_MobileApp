/** Khu vực trong campus — dùng lọc địa điểm trên bản đồ. */
export const PLACE_ZONES = [
  { id: 'khu_a', label: 'Khu A' },
  { id: 'khu_b', label: 'Khu B' },
  { id: 'library', label: 'Thư viện' },
  { id: 'dorm', label: 'Ký túc xá' },
  { id: 'cafeteria', label: 'Căng tin' },
  { id: 'sports', label: 'Sân thể thao' },
  { id: 'faculty_it', label: 'Khoa CNTT' },
  { id: 'faculty_biz', label: 'Khoa Kinh tế' },
  { id: 'other', label: 'Khác' },
] as const;

export type PlaceZoneId = (typeof PLACE_ZONES)[number]['id'];

const ZONE_IDS = new Set<string>(PLACE_ZONES.map((z) => z.id));

export const isValidPlaceZone = (zone?: string): boolean =>
  zone != null && ZONE_IDS.has(zone);
