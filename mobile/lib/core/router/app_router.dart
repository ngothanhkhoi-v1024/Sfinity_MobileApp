import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/content/presentation/pages/content_detail_page.dart';
import '../../features/content/presentation/pages/content_form_page.dart';
import '../../features/content/presentation/pages/content_list_page.dart';
import '../../features/feedback/presentation/pages/feedback_page.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
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
      final isAuthRoute = path == RouteNames.login || path == RouteNames.register;
      final isOnboarding = path == RouteNames.onboarding;

      if (!auth.isAuthenticated) {
        if (isAuthRoute || isOnboarding) return null;
        return RouteNames.login;
      }

      if (isAuthRoute || isOnboarding) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (_, __) => const HomeShellPage(),
      ),
      GoRoute(
        path: RouteNames.contentList,
        builder: (_, __) => const ContentListPage(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, __) => const ContentFormPage(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return ContentDetailPage(contentId: id);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return ContentFormPage(contentId: id);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (_, __) => const SettingsPage(),
      ),
      GoRoute(
        path: RouteNames.feedback,
        builder: (_, __) => const FeedbackPage(),
      ),
    ],
  );
}
