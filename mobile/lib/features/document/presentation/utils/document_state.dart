import 'content_state.dart';

const String documentVisibilityPrivate = contentVisibilityPrivate;
const String documentVisibilityPublic = contentVisibilityPublic;

const String documentModerationNone = contentModerationNone;
const String documentModerationPending = contentModerationPending;
const String documentModerationApproved = contentModerationApproved;
const String documentModerationRejected = contentModerationRejected;
const String documentModerationHidden = contentModerationHidden;

String documentVisibilityOf(Map<String, dynamic> item) => contentVisibilityOf(item);

String documentModerationStatusOf(Map<String, dynamic> item) =>
    contentModerationStatusOf(item);

String documentLegacyStatusOf(Map<String, dynamic> item) =>
    contentLegacyStatusOf(item);
