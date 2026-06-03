/// Named routes — dùng với GoRouter / Navigator sau.
abstract final class RouteNames {
  // Auth
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otpVerification = '/otp-verification';

  // Splash
  static const splash = '/splash';

  // Onboarding
  static const onboarding = '/onboarding';

  // Main shell
  static const home = '/';
  static const search = '/search';
  static const favorites = '/favorites';
  static const profile = '/profile';

  // Places
  static const placeDetail = '/places/:id';
  static const placeEdit = '/places/:id/edit';
  static const placeShare = '/places/share';

  // Document
  static const documentList = '/document';
  static const myDocuments = '/document/my';
  static const documentDetail = '/document/:id';
  static const documentCreate = '/document/create';
  static const documentEdit = '/document/:id/edit';

  // Notifications & settings
  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/settings';
  static const settings = '/settings';
  static const languageSettings = '/settings/language';
  static const themeSettings = '/settings/theme';

  // Profile & security
  static const viewProfile = '/profile/view';
  static const editProfile = '/profile/edit';
  static const changePassword = '/security/change-password';
  static const twoFactor = '/security/two-factor';
  static const sessions = '/security/sessions';

  // Other
  static const history = '/history';
  static const recentlyViewed = '/history/recent';
  static const feedback = '/feedback';
  static const rateApp = '/feedback/rate';
  static const report = '/report';

  // Group & Friends
  static const friends = '/friends';
  static const groups = '/groups';
  static const groupCreate = '/groups/create';
  static const groupEdit = '/groups/:id/edit';
  static const groupDetail = '/groups/:id';
  static const groupChat = '/groups/:id/chat';
}
