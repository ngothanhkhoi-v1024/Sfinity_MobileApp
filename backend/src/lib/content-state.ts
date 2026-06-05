import {
  ContentModerationStatus,
  ContentStatus,
  ContentVisibility,
} from '../types/enums';

export type ContentState = {
  visibility: ContentVisibility;
  moderationStatus: ContentModerationStatus;
};

const visibilityValues = new Set<string>(Object.values(ContentVisibility));
const moderationValues = new Set<string>(Object.values(ContentModerationStatus));
const publicModerationStatuses = new Set<ContentModerationStatus>([
  ContentModerationStatus.PENDING,
  ContentModerationStatus.APPROVED,
  ContentModerationStatus.REJECTED,
  ContentModerationStatus.HIDDEN,
]);

function migrateLegacyStatus(status: string): ContentState | null {
  switch (status) {
    case ContentStatus.DRAFT:
      return {
        visibility: ContentVisibility.PRIVATE,
        moderationStatus: ContentModerationStatus.NONE,
      };
    case ContentStatus.PENDING:
      return {
        visibility: ContentVisibility.PUBLIC,
        moderationStatus: ContentModerationStatus.PENDING,
      };
    case ContentStatus.PUBLISHED:
      return {
        visibility: ContentVisibility.PUBLIC,
        moderationStatus: ContentModerationStatus.APPROVED,
      };
    case ContentStatus.REJECTED:
      return {
        visibility: ContentVisibility.PUBLIC,
        moderationStatus: ContentModerationStatus.REJECTED,
      };
    case ContentStatus.HIDDEN:
      return {
        visibility: ContentVisibility.PUBLIC,
        moderationStatus: ContentModerationStatus.HIDDEN,
      };
    default:
      return null;
  }
}

export function normalizeContentState(item: any): ContentState {
  const visibility = item?.visibility?.toString();
  const moderationStatus = item?.moderationStatus?.toString();

  if (
    visibilityValues.has(visibility ?? '') &&
    moderationValues.has(moderationStatus ?? '')
  ) {
    const normalizedVisibility = visibility as ContentVisibility;
    let normalizedModeration = moderationStatus as ContentModerationStatus;

    if (normalizedVisibility === ContentVisibility.PRIVATE) {
      normalizedModeration = ContentModerationStatus.NONE;
    }

    if (
      normalizedVisibility === ContentVisibility.PUBLIC &&
      !publicModerationStatuses.has(normalizedModeration)
    ) {
      normalizedModeration = ContentModerationStatus.PENDING;
    }

    return {
      visibility: normalizedVisibility,
      moderationStatus: normalizedModeration,
    };
  }

  const legacy = migrateLegacyStatus(item?.status?.toString() ?? '');
  if (legacy) {
    return legacy;
  }

  return {
    visibility: ContentVisibility.PRIVATE,
    moderationStatus: ContentModerationStatus.NONE,
  };
}

export function applyContentState<T extends Record<string, any>>(
  item: T,
): T & ContentState {
  const state = normalizeContentState(item);
  return {
    ...item,
    visibility: state.visibility,
    moderationStatus: state.moderationStatus,
  };
}

export function isPubliclyVisible(item: any): boolean {
  const state = normalizeContentState(item);
  return (
    state.visibility === ContentVisibility.PUBLIC &&
    state.moderationStatus === ContentModerationStatus.APPROVED
  );
}

export function deriveRequestedVisibility(input: {
  visibility?: ContentVisibility | null;
}): ContentVisibility | undefined {
  if (
    input.visibility === ContentVisibility.PRIVATE ||
    input.visibility === ContentVisibility.PUBLIC
  ) {
    return input.visibility;
  }
  return undefined;
}

export function deriveRequestedModeration(input: {
  moderationStatus?: ContentModerationStatus | null;
}): ContentModerationStatus | undefined {
  if (input.moderationStatus && moderationValues.has(input.moderationStatus)) {
    return input.moderationStatus;
  }
  return undefined;
}

export function sanitizeAdminModeration(
  moderationStatus?: ContentModerationStatus,
): ContentModerationStatus {
  if (!moderationStatus || moderationStatus === ContentModerationStatus.NONE) {
    return ContentModerationStatus.APPROVED;
  }

  return publicModerationStatuses.has(moderationStatus)
    ? moderationStatus
    : ContentModerationStatus.APPROVED;
}
