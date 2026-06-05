const String contentVisibilityPrivate = 'PRIVATE';
const String contentVisibilityPublic = 'PUBLIC';

const String contentModerationNone = 'NONE';
const String contentModerationPending = 'PENDING';
const String contentModerationApproved = 'APPROVED';
const String contentModerationRejected = 'REJECTED';
const String contentModerationHidden = 'HIDDEN';

String contentVisibilityOf(Map<String, dynamic> item) {
  final visibility = item['visibility']?.toString().toUpperCase();
  if (visibility == contentVisibilityPrivate || visibility == contentVisibilityPublic) {
    return visibility!;
  }

  final status = item['status']?.toString().toUpperCase();
  if (status == 'DRAFT') {
    return contentVisibilityPrivate;
  }
  return contentVisibilityPublic;
}

String contentModerationStatusOf(Map<String, dynamic> item) {
  final moderation = item['moderationStatus']?.toString().toUpperCase();
  if (moderation == contentModerationNone ||
      moderation == contentModerationPending ||
      moderation == contentModerationApproved ||
      moderation == contentModerationRejected ||
      moderation == contentModerationHidden) {
    return moderation!;
  }

  final status = item['status']?.toString().toUpperCase();
  switch (status) {
    case 'PENDING':
      return contentModerationPending;
    case 'REJECTED':
      return contentModerationRejected;
    case 'HIDDEN':
      return contentModerationHidden;
    case 'PUBLISHED':
      return contentModerationApproved;
    case 'DRAFT':
    default:
      return contentModerationNone;
  }
}

bool contentIsPubliclyVisible(Map<String, dynamic> item) {
  return contentVisibilityOf(item) == contentVisibilityPublic &&
      contentModerationStatusOf(item) == contentModerationApproved;
}

String contentLegacyStatusOf(Map<String, dynamic> item) {
  final visibility = contentVisibilityOf(item);
  final moderation = contentModerationStatusOf(item);

  if (visibility == contentVisibilityPrivate) {
    return 'DRAFT';
  }

  switch (moderation) {
    case contentModerationPending:
      return 'PENDING';
    case contentModerationRejected:
      return 'REJECTED';
    case contentModerationHidden:
      return 'HIDDEN';
    case contentModerationApproved:
      return 'PUBLISHED';
    default:
      return 'DRAFT';
  }
}
