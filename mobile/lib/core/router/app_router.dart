import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/content/presentation/pages/content_detail_page.dart';
import '../../features/content/presentation/pages/content_form_page.dart';
import '../../features/content/presentation/pages/content_list_page.dart';
import '../../features/feedback/presentation/pages/feedback_page.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/places/presentation/pages/place_share_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/report/presentation/pages/report_page.dart';
import '../../features/security/presentation/pages/change_password_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../auth/auth_state.dart';
import '../constants/route_names.dart';

GoRouter createAppRouter(AuthState auth) {
  return GoRouter(
    initialLocation: RouteNames.onboarding,
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.isLoading) return null;

      final path = state.matchedLocation;
      final publicRoutes = {
        RouteNames.login,
        RouteNames.register,
        RouteNames.onboarding,
        RouteNames.forgotPassword,
        RouteNames.otpVerification,
      };

      if (!auth.isAuthenticated) {
        if (publicRoutes.contains(path)) return null;
        return RouteNames.login;
      }

      if (publicRoutes.contains(path)) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(path: RouteNames.onboarding, builder: (_, __) => const OnboardingPage()),
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: RouteNames.register, builder: (_, __) => const RegisterPage()),
      GoRoute(path: RouteNames.forgotPassword, builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(path: RouteNames.otpVerification, builder: (_, __) => const OtpVerificationPage()),
      GoRoute(path: RouteNames.home, builder: (_, __) => const HomeShellPage()),
      GoRoute(path: RouteNames.search, builder: (_, __) => const SearchPage()),
      GoRoute(path: RouteNames.favorites, builder: (_, __) => const FavoritesPage()),
      GoRoute(path: RouteNames.placeShare, builder: (_, __) => const PlaceSharePage()),
      GoRoute(
        path: RouteNames.contentList,
        builder: (_, __) => const ContentListPage(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, state) {
              final extra = state.extra;
              final type = extra is Map ? extra['contentType']?.toString() ?? 'document' : 'document';
              return ContentFormPage(contentType: type);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) => ContentDetailPage(contentId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) => ContentFormPage(contentId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: RouteNames.settings, builder: (_, __) => const SettingsPage()),
      GoRoute(path: RouteNames.feedback, builder: (_, __) => const FeedbackPage()),
      GoRoute(path: RouteNames.report, builder: (_, __) => const ReportPage()),
      GoRoute(path: RouteNames.notifications, builder: (_, __) => const NotificationsPage()),
      GoRoute(path: RouteNames.editProfile, builder: (_, __) => const EditProfilePage()),
      GoRoute(path: RouteNames.changePassword, builder: (_, __) => const ChangePasswordPage()),
    ],
  );
}
