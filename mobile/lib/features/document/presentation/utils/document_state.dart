const String documentVisibilityPrivate = 'PRIVATE';
const String documentVisibilityPublic = 'PUBLIC';

const String documentModerationNone = 'NONE';
const String documentModerationPending = 'PENDING';
const String documentModerationApproved = 'APPROVED';
const String documentModerationRejected = 'REJECTED';
const String documentModerationHidden = 'HIDDEN';

String documentVisibilityOf(Map<String, dynamic> item) {
  final visibility = item['visibility']?.toString().toUpperCase();
  if (visibility == documentVisibilityPrivate || visibility == documentVisibilityPublic) {
    return visibility!;
  }

  final status = item['status']?.toString().toUpperCase();
  if (status == 'DRAFT') {
    return documentVisibilityPrivate;
  }
  return documentVisibilityPublic;
}

String documentModerationStatusOf(Map<String, dynamic> item) {
  final moderation = item['moderationStatus']?.toString().toUpperCase();
  if (moderation == documentModerationNone ||
      moderation == documentModerationPending ||
      moderation == documentModerationApproved ||
      moderation == documentModerationRejected ||
      moderation == documentModerationHidden) {
    return moderation!;
  }

  final status = item['status']?.toString().toUpperCase();
  switch (status) {
    case 'PENDING':
      return documentModerationPending;
    case 'REJECTED':
      return documentModerationRejected;
    case 'HIDDEN':
      return documentModerationHidden;
    case 'PUBLISHED':
      return documentModerationApproved;
    case 'DRAFT':
    default:
      return documentModerationNone;
  }
}

String documentLegacyStatusOf(Map<String, dynamic> item) {
  final visibility = documentVisibilityOf(item);
  final moderation = documentModerationStatusOf(item);

  if (visibility == documentVisibilityPrivate) {
    return 'DRAFT';
  }

  switch (moderation) {
    case documentModerationPending:
      return 'PENDING';
    case documentModerationRejected:
      return 'REJECTED';
    case documentModerationHidden:
      return 'HIDDEN';
    case documentModerationApproved:
      return 'PUBLISHED';
    default:
      return 'DRAFT';
  }
}
