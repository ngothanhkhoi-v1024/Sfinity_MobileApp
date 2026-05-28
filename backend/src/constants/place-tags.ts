/** Tag tiện ích học tập cho địa điểm (type=place). */
export const PLACE_STUDY_TAGS = [
  'wifi',
  'outlet',
  'quiet',
  'open_late',
  'ac',
  'parking',
] as const;

export type PlaceStudyTag = (typeof PLACE_STUDY_TAGS)[number];

export const parseTagsQuery = (raw?: string): string[] => {
  if (!raw?.trim()) return [];
  return raw
    .split(',')
    .map((t) => t.trim().toLowerCase())
    .filter((t) => t.length > 0);
};

export const itemHasAllTags = (item: { tags?: unknown }, required: string[]): boolean => {
  if (required.length === 0) return true;
  const itemTags = Array.isArray(item.tags)
    ? item.tags.map((t) => String(t).toLowerCase())
    : [];
  return required.every((t) => itemTags.includes(t));
};
