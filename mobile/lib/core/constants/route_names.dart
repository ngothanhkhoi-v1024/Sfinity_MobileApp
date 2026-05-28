/// Named routes — dùng với GoRouter / Navigator sau.
abstract final class RouteNames {
  // Auth
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otpVerification = '/otp-verification';

  // Onboarding
  static const onboarding = '/onboarding';

  // Main shell
  static const home = '/';
  static const search = '/search';
  static const favorites = '/favorites';
  static const profile = '/profile';

  // Places
  static const placeShare = '/places/share';

  // Document
  static const documentList = '/document';
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
}
