import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/document/presentation/pages/document_detail_page.dart';
import '../../features/document/presentation/pages/document_form_page.dart';
import '../../features/document/presentation/pages/document_list_page.dart';
import '../../features/document/presentation/pages/my_documents_page.dart';
import '../../features/feedback/presentation/pages/feedback_page.dart';
import '../../features/friendships/presentation/pages/friends_page.dart';
import '../../features/groups/presentation/pages/group_chat_page.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/groups/presentation/pages/group_list_page.dart';
import '../../features/groups/presentation/pages/group_form_page.dart';
import '../../features/friendships/data/models/friend_model.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/places/presentation/pages/place_detail_page.dart';
import '../../features/places/presentation/pages/place_share_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/view_profile_page.dart';
import '../../features/report/presentation/pages/report_page.dart';
import '../../features/security/presentation/pages/change_password_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../auth/auth_state.dart';
import '../constants/route_names.dart';

GoRouter createAppRouter(AuthState auth) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.isLoading) return null;

      final path = state.matchedLocation;
      final publicRoutes = {
        RouteNames.splash,
        RouteNames.login,
        RouteNames.register,
        RouteNames.onboarding,
        RouteNames.forgotPassword,
        RouteNames.otpVerification,
      };

      if (path == RouteNames.splash) return null;

      if (!auth.isAuthenticated) {
        if (publicRoutes.contains(path)) return null;
        return RouteNames.login;
      }

      if (publicRoutes.contains(path)) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(path: RouteNames.splash, builder: (_, __) => const SplashPage()),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginPage()),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.otpVerification,
        builder: (_, __) => const OtpVerificationPage(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (_, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = tabStr != null ? (int.tryParse(tabStr) ?? 0) : 0;
          return HomeShellPage(initialTab: initialTab);
        },
      ),
      GoRoute(path: RouteNames.search, builder: (_, __) => const SearchPage()),
      GoRoute(
        path: RouteNames.favorites,
        builder: (_, __) => const FavoritesPage(),
      ),
      // /places/share phải đứng trước /places/:id, nếu không "share" bị match nhầm thành id.
      GoRoute(
        path: RouteNames.placeShare,
        builder: (_, __) => const PlaceSharePage(),
      ),
      GoRoute(
        path: RouteNames.placeEdit,
        builder: (_, state) =>
            PlaceSharePage(editPlaceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.placeDetail,
        builder: (_, state) =>
            PlaceDetailPage(placeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.documentList,
        builder: (_, __) => const DocumentListPage(),
        routes: [
          GoRoute(
            path: 'my',
            builder: (_, __) => const MyDocumentsPage(),
          ),
          GoRoute(
            path: 'create',
            builder: (_, state) {
              final extra = state.extra;
              final map = extra is Map ? extra : null;
              final type = map?['contentType']?.toString() ?? 'document';
              return DocumentFormPage(
                contentType: type,
                placeId: map?['placeId']?.toString(),
                placeTitle: map?['placeTitle']?.toString(),
              );
            },
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                DocumentDetailPage(documentId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) =>
                    DocumentFormPage(documentId: state.pathParameters['id']!),
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
        path: RouteNames.notificationSettings,
        builder: (_, __) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: RouteNames.feedback,
        builder: (_, __) => const FeedbackPage(),
      ),
      GoRoute(path: RouteNames.report, builder: (_, __) => const ReportPage()),
      GoRoute(
        path: RouteNames.notifications,
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: RouteNames.viewProfile,
        builder: (_, state) => ViewProfilePage(
          profileUser: state.extra is FriendUser ? state.extra as FriendUser : null,
        ),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: RouteNames.changePassword,
        builder: (_, __) => const ChangePasswordPage(),
      ),
      // Group & Friends routes
      GoRoute(
        path: RouteNames.friends,
        builder: (_, __) => const FriendsPage(),
      ),
      GoRoute(
        path: RouteNames.groups,
        builder: (_, __) => const GroupListPage(),
      ),
      GoRoute(
        path: RouteNames.groupCreate,
        builder: (_, __) => const GroupFormPage(),
      ),
      GoRoute(
        path: RouteNames.groupEdit,
        builder: (_, state) =>
            GroupFormPage(groupId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (_, state) =>
            GroupDetailPage(groupId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (_, state) => GroupChatPage(
              groupId: state.pathParameters['id']!,
              groupName: state.uri.queryParameters['name'],
            ),
          ),
        ],
      ),
    ],
  );
}
