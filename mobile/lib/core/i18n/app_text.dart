import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  static const supportedLocales = [Locale('vi'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  final Locale locale;

  static const Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      'appName': 'Sfinity',
      'explore': 'Khám phá',
      'places': 'Địa điểm',
      'documents': 'Tài liệu',
      'viewContent': 'Xem nội dung',
      'publishedPostsList': 'Danh sách bài viết đã xuất bản',
      'profile': 'Cá nhân',
      'search': 'Tìm kiếm',
      'saved': 'Đã lưu',
      'settings': 'Cài đặt',
      'notifications': 'Thông báo',
      'notificationsInApp': 'Thông báo trong ứng dụng',
      'receiveInAppNotifications': 'Nhận thông báo in-app',
      'inAppNotificationSettings': 'Thông báo trong ứng dụng',
      'notificationSettingsDescription': 'Quản lý việc nhận và hiển thị thông báo trong ứng dụng.',
      'notificationsDisabled': 'Đã tắt thông báo',
      'notificationsDisabledDescription': 'Bạn sẽ không thấy danh sách thông báo trong ứng dụng cho đến khi bật lại.',
      'enableNotifications': 'Bật lại thông báo',
      'theme': 'Giao diện',
      'changePassword': 'Đổi mật khẩu',
      'language': 'Ngôn ngữ',
      'system': 'Hệ thống',
      'light': 'Sáng',
      'dark': 'Tối',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'useAppInVietnamese': 'Sử dụng giao diện tiếng Việt',
      'useAppInEnglish': 'Sử dụng giao diện tiếng Anh',
      'editProfile': 'Chỉnh sửa hồ sơ',
      'viewProfile': 'Xem hồ sơ',
      'bio': 'Giới thiệu bản thân',
      'myPosts': 'Bài đăng của tôi',
      'feedback': 'Phản hồi',
      'reportViolation': 'Báo cáo vi phạm',
      'signOut': 'Đăng xuất',
      'shareOnSfinity': 'Chia sẻ trên Sfinity',
      'shareDescription': 'Địa điểm học tập hoặc tài liệu cho cộng đồng',
      'sharePlace': 'Chia sẻ địa điểm',
      'sharePlaceSubtitle': 'Thư viện, quán cà phê, không gian học nhóm…',
      'uploadStudyMaterials': 'Đăng tài liệu học tập',
      'uploadStudyMaterialsSubtitle': 'Ghi chú, slide, đề thi, tóm tắt môn học…',
      'retry': 'Thử lại',
      'searchHint': 'Tìm kiếm...',
      'noNotifications': 'Không có thông báo',
      'markAllRead': 'Đọc tất cả',
      'deleteNotification': 'Xóa thông báo',
      'deleteAllNotifications': 'Xóa tất cả thông báo',
      'deleteAllNotificationsConfirm': 'Bạn có chắc muốn xóa tất cả thông báo?',
      'deleteNotificationConfirm': 'Bạn có chắc muốn xóa thông báo này?',
      'yesDelete': 'Xóa',
      'cancel': 'Hủy',
      'noFavoritesYet': 'Chưa có mục yêu thích',
      'sendFeedback': 'Gửi phản hồi',
      'ratingLabel': 'Đánh giá: {rating} sao',
      'feedbackContent': 'Nội dung phản hồi',
      'submit': 'Gửi',
      'enterAtLeast5Characters': 'Nhập ít nhất 5 ký tự',
      'thanksForYourFeedback': 'Cảm ơn phản hồi của bạn!',
      'reportSubmitted': 'Đã gửi báo cáo',
      'reportViolationTitle': 'Báo cáo vi phạm',
      'type': 'Loại',
      'documentType': 'Tài liệu',
      'userType': 'Người dùng',
      'otherType': 'Khác',
      'targetIdOptional': 'ID đối tượng (tuỳ chọn)',
      'reason': 'Lý do',
      'detailedDescription': 'Mô tả chi tiết',
      'submitReport': 'Gửi báo cáo',
      'login': 'Đăng nhập',
      'welcomeBack': 'Chào mừng bạn quay lại với Sfinity.',
      'email': 'Email',
      'password': 'Mật khẩu',
      'forgotPasswordQuestion': 'Quên mật khẩu?',
      'orContinueWith': 'Hoặc tiếp tục với',
      'continueWithGoogle': 'Đăng nhập với Google',
      'noAccountYetRegister': 'Chưa có tài khoản? Đăng ký',
      'forgotPassword': 'Quên mật khẩu',
      'forgotPasswordDescription': 'Nhập email đã đăng ký để nhận mã OTP khôi phục mật khẩu.',
      'sendOtp': 'Gửi mã OTP',
      'backToSignIn': 'Quay lại đăng nhập',
      'otpVerification': 'Xác thực OTP',
      'otpDescription': 'Nhập mã OTP gồm 6 chữ số đã được gửi tới email của bạn:',
      'otpCode6Digits': 'Mã OTP (6 chữ số)',
      'newPassword': 'Mật khẩu mới',
      'resetPassword': 'Đặt lại mật khẩu',
      'passwordResetSuccessful': 'Đặt lại mật khẩu thành công',
      'welcomeTitle': 'Chào mừng Sfinity',
      'welcomeSubtitle': 'Khám phá nội dung và quản lý yêu thích của bạn.',
      'smartSearchTitle': 'Tìm kiếm thông minh',
      'smartSearchSubtitle': 'Lọc, sắp xếp và tìm nội dung nhanh chóng.',
      'stayConnectedTitle': 'Kết nối mọi lúc',
      'stayConnectedSubtitle': 'Đăng nhập để đồng bộ dữ liệu trên mọi thiết bị.',
      'next': 'Tiếp theo',
      'getStarted': 'Bắt đầu',
      'emailVerified': 'Email',
      'signIn': 'Đăng nhập',
      'welcomeTitleShort': 'Chào mừng Sfinity',
      'welcomeDescShort': 'Khám phá nội dung và quản lý yêu thích của bạn.',
      'studyPlacesOrMaterials': 'Địa điểm học tập hoặc tài liệu cho cộng đồng',
      'libraryCafeStudyGroupSpace': 'Thư viện, quán cà phê, không gian học nhóm…',
      'notesSlidesExamPapersSubjectSummaries': 'Ghi chú, slide, đề thi, tóm tắt môn học…',
      'createGroupTitle': 'Tạo nhóm mới',
      'editGroupTitle': 'Chỉnh sửa thông tin nhóm',
      'groupNameLabel': 'Tên nhóm *',
      'groupNameHint': 'Nhập tên nhóm của bạn',
      'groupDescLabel': 'Mô tả (tùy chọn)',
      'groupDescHint': 'Thêm vài lời về nhóm này...',
      'publicGroupLabel': 'Nhóm công khai',
      'publicGroupHint': 'Bất kỳ ai cũng có thể tìm và gia nhập nhóm này.',
      'privateGroupHint': 'Chỉ những thành viên được mời mới có thể tham gia.',
      'autoApproveLabel': 'Tự động duyệt thành viên',
      'autoApproveHint': 'Thành viên mới tham gia trực tiếp không cần phê duyệt.',
      'requireApprovalHint': 'Thành viên mới cần được chủ nhóm phê duyệt trước.',
      'createGroupBtn': 'Tạo nhóm',
      'saveChangesBtn': 'Lưu thay đổi',
      'cancelBtn': 'Hủy',
      'joinRequestsLabel': 'Yêu cầu duyệt',
      'approveBtn': 'Duyệt',
      'declineBtn': 'Từ chối',
      'welcomeDescription': 'Khám phá hàng nghìn địa điểm học tập và tài liệu được cộng đồng chia sẻ. Lưu lại những gì yêu thích và truy cập mọi lúc.',
      'smartSearchDescription': 'Bộ lọc thông minh giúp bạn tìm đúng nội dung trong vài giây. Sắp xếp theo chủ đề, khoảng cách hoặc mức độ phù hợp.',
      'stayConnectedDescription': 'Đăng nhập một lần, dữ liệu tự động đồng bộ trên tất cả thiết bị. Không bao giờ mất đi nội dung yêu thích dù đổi điện thoại.',
      'welcomeBadge': 'Nền tảng học tập',
      'smartSearchBadge': 'Nhanh & chính xác',
      'stayConnectedBadge': 'Đa thiết bị',
      'skip': 'Bỏ qua',
      'getStartedNow': 'Bắt đầu ngay',
    },
    'en': {
      'appName': 'Sfinity',
      'explore': 'Explore',
      'places': 'Places',
      'documents': 'Documents',
      'viewContent': 'View content',
      'publishedPostsList': 'List of published posts',
      'profile': 'Profile',
      'search': 'Search',
      'saved': 'Saved',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'notificationsInApp': 'In-app notifications',
      'receiveInAppNotifications': 'Receive in-app notifications',
      'inAppNotificationSettings': 'In-app notifications',
      'notificationSettingsDescription': 'Manage how in-app notifications are received and displayed.',
      'notificationsDisabled': 'Notifications turned off',
      'notificationsDisabledDescription': 'You will not see the in-app notification list until you turn it back on.',
      'enableNotifications': 'Enable notifications',
      'theme': 'Theme',
      'changePassword': 'Change password',
      'language': 'Language',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'vietnamese': 'Vietnamese',
      'english': 'English',
      'useAppInVietnamese': 'Use the app in Vietnamese',
      'useAppInEnglish': 'Use the app in English',
      'editProfile': 'Edit profile',
      'viewProfile': 'View profile',
      'bio': 'About me',
      'myPosts': 'My posts',
      'feedback': 'Feedback',
      'reportViolation': 'Report violation',
      'signOut': 'Sign out',
      'shareOnSfinity': 'Share on Sfinity',
      'shareDescription': 'Study places or materials for the community',
      'sharePlace': 'Share a place',
      'sharePlaceSubtitle': 'Library, café, study group space…',
      'uploadStudyMaterials': 'Upload study materials',
      'uploadStudyMaterialsSubtitle': 'Notes, slides, exam papers, subject summaries…',
      'retry': 'Retry',
      'searchHint': 'Search...',
      'noNotifications': 'No notifications',
      'markAllRead': 'Mark all read',
      'deleteNotification': 'Delete notification',
      'deleteAllNotifications': 'Delete all notifications',
      'deleteAllNotificationsConfirm': 'Are you sure you want to delete all notifications?',
      'deleteNotificationConfirm': 'Are you sure you want to delete this notification?',
      'yesDelete': 'Delete',
      'cancel': 'Cancel',
      'noFavoritesYet': 'No favorites yet',
      'sendFeedback': 'Send feedback',
      'ratingLabel': 'Rating: {rating} stars',
      'feedbackContent': 'Feedback content',
      'submit': 'Submit',
      'enterAtLeast5Characters': 'Enter at least 5 characters',
      'thanksForYourFeedback': 'Thanks for your feedback!',
      'reportSubmitted': 'Report submitted',
      'reportViolationTitle': 'Report violation',
      'type': 'Type',
      'documentType': 'Document',
      'userType': 'User',
      'otherType': 'Other',
      'targetIdOptional': 'Target ID (optional)',
      'reason': 'Reason',
      'detailedDescription': 'Detailed description',
      'submitReport': 'Submit report',
      'login': 'Sign in',
      'welcomeBack': 'Welcome back to Sfinity.',
      'email': 'Email',
      'password': 'Password',
      'forgotPasswordQuestion': 'Forgot password?',
      'orContinueWith': 'Or continue with',
      'continueWithGoogle': 'Continue with Google',
      'noAccountYetRegister': 'No account yet? Register',
      'forgotPassword': 'Forgot password',
      'forgotPasswordDescription': 'Enter your registered email to receive a password reset OTP.',
      'sendOtp': 'Send OTP',
      'backToSignIn': 'Back to sign in',
      'otpVerification': 'OTP verification',
      'otpDescription': 'Enter the 6-digit OTP sent to your email:',
      'otpCode6Digits': 'OTP code (6 digits)',
      'newPassword': 'New password',
      'resetPassword': 'Reset password',
      'passwordResetSuccessful': 'Password reset successful',
      'welcomeTitle': 'Welcome to Sfinity',
      'welcomeSubtitle': 'Discover content and manage your favorites.',
      'smartSearchTitle': 'Smart search',
      'smartSearchSubtitle': 'Filter, sort, and find content quickly.',
      'stayConnectedTitle': 'Stay connected',
      'stayConnectedSubtitle': 'Sign in to sync your data across devices.',
      'next': 'Next',
      'getStarted': 'Get started',
      'emailVerified': 'Email',
      'signIn': 'Sign in',
      'welcomeTitleShort': 'Welcome to Sfinity',
      'welcomeDescShort': 'Discover content and manage your favorites.',
      'studyPlacesOrMaterials': 'Study places or materials for the community',
      'libraryCafeStudyGroupSpace': 'Library, café, study group space…',
      'notesSlidesExamPapersSubjectSummaries': 'Notes, slides, exam papers, subject summaries…',
      'createGroupTitle': 'Create new group',
      'editGroupTitle': 'Edit group details',
      'groupNameLabel': 'Group name *',
      'groupNameHint': 'Enter your group name',
      'groupDescLabel': 'Description (optional)',
      'groupDescHint': 'Add a few words about this group...',
      'publicGroupLabel': 'Public group',
      'publicGroupHint': 'Anyone can find and join this group.',
      'privateGroupHint': 'Only invited members can join.',
      'autoApproveLabel': 'Auto-approve members',
      'autoApproveHint': 'New members join directly without approval.',
      'requireApprovalHint': 'New members need owner approval first.',
      'createGroupBtn': 'Create group',
      'saveChangesBtn': 'Save changes',
      'cancelBtn': 'Cancel',
      'joinRequestsLabel': 'Join requests',
      'approveBtn': 'Approve',
      'declineBtn': 'Decline',
      'welcomeDescription': 'Discover thousands of study spots and community-shared materials. Save your favorites and access them anytime.',
      'smartSearchDescription': 'Smart filters help you find the right content in seconds. Sort by topic, distance, or relevance.',
      'stayConnectedDescription': 'Sign in once and your data syncs automatically across all devices. Never lose your favorites when switching phones.',
      'welcomeBadge': 'Learning platform',
      'smartSearchBadge': 'Fast & accurate',
      'stayConnectedBadge': 'Multi-device',
      'skip': 'Skip',
      'getStartedNow': 'Get started',
    },
  };

  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  String _text(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;

  String _format(String key, Map<String, String> replacements) {
    var value = _text(key);
    replacements.forEach((placeholder, replacement) {
      value = value.replaceAll(placeholder, replacement);
    });
    return value;
  }

  String get appName => _text('appName');
  String get explore => _text('explore');
  String get places => _text('places');
  String get documents => _text('documents');
  String get viewContent => _text('viewContent');
  String get publishedPostsList => _text('publishedPostsList');
  String get profile => _text('profile');
  String get search => _text('search');
  String get saved => _text('saved');
  String get settings => _text('settings');
  String get notifications => _text('notifications');
  String get notificationsInApp => _text('notificationsInApp');
  String get receiveInAppNotifications => _text('receiveInAppNotifications');
  String get inAppNotificationSettings => _text('inAppNotificationSettings');
  String get notificationSettingsDescription => _text('notificationSettingsDescription');
  String get notificationsDisabled => _text('notificationsDisabled');
  String get notificationsDisabledDescription => _text('notificationsDisabledDescription');
  String get enableNotifications => _text('enableNotifications');
  String get theme => _text('theme');
  String get changePassword => _text('changePassword');
  String get language => _text('language');
  String get system => _text('system');
  String get light => _text('light');
  String get dark => _text('dark');
  String get vietnamese => _text('vietnamese');
  String get english => _text('english');
  String get useAppInVietnamese => _text('useAppInVietnamese');
  String get useAppInEnglish => _text('useAppInEnglish');
  String get editProfile => _text('editProfile');
  String get viewProfile => _text('viewProfile');
  String get bio => _text('bio');
  String get myPosts => _text('myPosts');
  String get feedback => _text('feedback');
  String get reportViolation => _text('reportViolation');
  String get signOut => _text('signOut');
  String get shareOnSfinity => _text('shareOnSfinity');
  String get shareDescription => _text('shareDescription');
  String get sharePlace => _text('sharePlace');
  String get sharePlaceSubtitle => _text('sharePlaceSubtitle');
  String get uploadStudyMaterials => _text('uploadStudyMaterials');
  String get uploadStudyMaterialsSubtitle => _text('uploadStudyMaterialsSubtitle');
  String get retry => _text('retry');
  String get searchHint => _text('searchHint');
  String get noNotifications => _text('noNotifications');
  String get markAllRead => _text('markAllRead');
  String get deleteNotification => _text('deleteNotification');
  String get deleteAllNotifications => _text('deleteAllNotifications');
  String get deleteAllNotificationsConfirm => _text('deleteAllNotificationsConfirm');
  String get deleteNotificationConfirm => _text('deleteNotificationConfirm');
  String get yesDelete => _text('yesDelete');
  String get cancel => _text('cancel');
  String get noFavoritesYet => _text('noFavoritesYet');
  String get sendFeedback => _text('sendFeedback');
  String ratingLabel(int rating) => _format('ratingLabel', {'{rating}': '$rating'});
  String get feedbackContent => _text('feedbackContent');
  String get submit => _text('submit');
  String get enterAtLeast5Characters => _text('enterAtLeast5Characters');
  String get thanksForYourFeedback => _text('thanksForYourFeedback');
  String get reportSubmitted => _text('reportSubmitted');
  String get reportViolationTitle => _text('reportViolationTitle');
  String get type => _text('type');
  String get documentType => _text('documentType');
  String get userType => _text('userType');
  String get otherType => _text('otherType');
  String get targetIdOptional => _text('targetIdOptional');
  String get reason => _text('reason');
  String get detailedDescription => _text('detailedDescription');
  String get submitReport => _text('submitReport');
  String get login => _text('login');
  String get welcomeBack => _text('welcomeBack');
  String get email => _text('email');
  String get password => _text('password');
  String get forgotPasswordQuestion => _text('forgotPasswordQuestion');
  String get orContinueWith => _text('orContinueWith');
  String get continueWithGoogle => _text('continueWithGoogle');
  String get noAccountYetRegister => _text('noAccountYetRegister');
  String get forgotPassword => _text('forgotPassword');
  String get forgotPasswordDescription => _text('forgotPasswordDescription');
  String get sendOtp => _text('sendOtp');
  String get backToSignIn => _text('backToSignIn');
  String get otpVerification => _text('otpVerification');
  String get otpDescription => _text('otpDescription');
  String get otpCode6Digits => _text('otpCode6Digits');
  String get newPassword => _text('newPassword');
  String get resetPassword => _text('resetPassword');
  String get passwordResetSuccessful => _text('passwordResetSuccessful');
  String get welcomeTitle => _text('welcomeTitle');
  String get welcomeSubtitle => _text('welcomeSubtitle');
  String get smartSearchTitle => _text('smartSearchTitle');
  String get smartSearchSubtitle => _text('smartSearchSubtitle');
  String get stayConnectedTitle => _text('stayConnectedTitle');
  String get stayConnectedSubtitle => _text('stayConnectedSubtitle');
  String get next => _text('next');
  String get getStarted => _text('getStarted');
  String get welcomeTitleShort => _text('welcomeTitleShort');
  String get welcomeDescShort => _text('welcomeDescShort');
  String get studyPlacesOrMaterials => _text('studyPlacesOrMaterials');
  String get libraryCafeStudyGroupSpace => _text('libraryCafeStudyGroupSpace');
  String get notesSlidesExamPapersSubjectSummaries => _text('notesSlidesExamPapersSubjectSummaries');
  String get createGroupTitle => _text('createGroupTitle');
  String get editGroupTitle => _text('editGroupTitle');
  String get groupNameLabel => _text('groupNameLabel');
  String get groupNameHint => _text('groupNameHint');
  String get groupDescLabel => _text('groupDescLabel');
  String get groupDescHint => _text('groupDescHint');
  String get publicGroupLabel => _text('publicGroupLabel');
  String get publicGroupHint => _text('publicGroupHint');
  String get privateGroupHint => _text('privateGroupHint');
  String get autoApproveLabel => _text('autoApproveLabel');
  String get autoApproveHint => _text('autoApproveHint');
  String get requireApprovalHint => _text('requireApprovalHint');
  String get createGroupBtn => _text('createGroupBtn');
  String get saveChangesBtn => _text('saveChangesBtn');
  String get cancelBtn => _text('cancelBtn');
  String get joinRequestsLabel => _text('joinRequestsLabel');
  String get approveBtn => _text('approveBtn');
  String get declineBtn => _text('declineBtn');
  String get welcomeDescription => _text('welcomeDescription');
  String get smartSearchDescription => _text('smartSearchDescription');
  String get stayConnectedDescription => _text('stayConnectedDescription');
  String get welcomeBadge => _text('welcomeBadge');
  String get smartSearchBadge => _text('smartSearchBadge');
  String get stayConnectedBadge => _text('stayConnectedBadge');
  String get skip => _text('skip');
  String get getStartedNow => _text('getStartedNow');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}


