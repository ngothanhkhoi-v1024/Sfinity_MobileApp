import '../../../document/presentation/utils/content_state.dart';

const String placeVisibilityPrivate = contentVisibilityPrivate;
const String placeVisibilityPublic = contentVisibilityPublic;

const String placeModerationNone = contentModerationNone;
const String placeModerationPending = contentModerationPending;
const String placeModerationApproved = contentModerationApproved;
const String placeModerationRejected = contentModerationRejected;
const String placeModerationHidden = contentModerationHidden;

String placeVisibilityOf(Map<String, dynamic> item) => contentVisibilityOf(item);

String placeModerationStatusOf(Map<String, dynamic> item) =>
    contentModerationStatusOf(item);

bool placeIsPubliclyVisible(Map<String, dynamic> item) =>
    contentIsPubliclyVisible(item);

String placeLegacyStatusOf(Map<String, dynamic> item) =>
    contentLegacyStatusOf(item);
