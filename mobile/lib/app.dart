import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/auth/auth_state.dart';
import 'core/network/api_client.dart';
import 'core/i18n/app_text.dart';
import 'core/router/app_router.dart';
import 'core/services/locale_manager.dart';
import 'core/services/notification_manager.dart';
import 'core/services/theme_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/services/auth_api_service.dart';
import 'features/auth/data/services/auth_local_database.dart';
import 'features/auth/data/services/firebase_auth_service.dart';
import 'features/auth/data/services/firestore_user_service.dart';
import 'features/auth/data/services/social_auth_service.dart';
import 'features/document/data/repositories/document_repository.dart';
import 'features/document/data/repositories/document_repository_impl.dart';
import 'features/document/data/services/document_api_service.dart';
import 'features/group/data/repositories/friendship_repository_impl.dart';
import 'features/group/data/repositories/group_repository_impl.dart';
import 'features/group/data/services/friendship_api_service.dart';
import 'features/group/data/services/group_api_service.dart';
import 'features/group/presentation/controllers/friendship_controller.dart';
import 'features/group/presentation/controllers/group_controller.dart';
import 'features/place_reviews/data/repositories/place_engagement_repository.dart';
import 'features/place_reviews/data/repositories/place_engagement_repository_impl.dart';
import 'features/place_reviews/data/services/place_engagement_api_service.dart';
import 'features/places/data/repositories/place_repository.dart';
import 'features/places/data/repositories/place_repository_impl.dart';
import 'features/places/data/services/place_api_service.dart';
import 'features/places/data/services/place_location_service.dart';
import 'features/study_near_me/data/repositories/study_near_me_repository.dart';
import 'features/study_near_me/data/repositories/study_near_me_repository_impl.dart';
import 'features/study_near_me/data/services/study_near_me_api_service.dart';

class SfinityApp extends StatefulWidget {
  const SfinityApp({super.key});

  static AuthState get auth => _SfinityAppState.auth;
  static late final DocumentRepository documentRepository;
  static late final PlaceRepository placeRepository;
  static late final StudyNearMeRepository studyNearMeRepository;
  static late final PlaceEngagementRepository placeEngagementRepository;
  static late final FriendshipController friendshipController;
  static late final GroupController groupController;
  static LocaleManager get localeManager => _SfinityAppState.localeManager;
  static NotificationManager get notificationManager => _SfinityAppState.notificationManager;
  static ThemeManager get themeManager => _SfinityAppState.themeManager;

  @override
  State<SfinityApp> createState() => _SfinityAppState();
}

class _SfinityAppState extends State<SfinityApp> {
  static late final AuthState auth;
  static late final LocaleManager localeManager;
  static late final NotificationManager notificationManager;
  static late final ThemeManager themeManager;
  late final GoRouter _router = createAppRouter(auth);

  @override
  void initState() {
    super.initState();
    final apiService = AuthApiService(ApiClient.instance);
    final docApiService = DocumentApiService(ApiClient.instance);
    SfinityApp.documentRepository = DocumentRepositoryImpl(docApiService);
    SfinityApp.placeRepository = PlaceRepositoryImpl(
      PlaceApiService(docApiService),
      PlaceLocationService(),
    );
    SfinityApp.studyNearMeRepository = StudyNearMeRepositoryImpl(
      StudyNearMeApiService(ApiClient.instance),
      PlaceLocationService(),
    );
    SfinityApp.placeEngagementRepository = PlaceEngagementRepositoryImpl(
      PlaceEngagementApiService(ApiClient.instance),
    );

    // Group feature
    final friendshipApiService = FriendshipApiService(ApiClient.instance);
    final groupApiService = GroupApiService(ApiClient.instance);
    SfinityApp.friendshipController = FriendshipController(
      FriendshipRepositoryImpl(friendshipApiService),
    );
    SfinityApp.groupController = GroupController(
      GroupRepositoryImpl(groupApiService),
    );

    final localDatabase = AuthLocalDatabase();
    final firebaseAuthService = FirebaseAuthService();
    final socialAuthService = SocialAuthService();
    final firestoreUserService = FirestoreUserService();

    final authRepository = AuthRepositoryImpl(
      apiService: apiService,
      localDatabase: localDatabase,
      firebaseAuthService: firebaseAuthService,
      socialAuthService: socialAuthService,
      firestoreUserService: firestoreUserService,
    );

    auth = AuthState(authRepository);
    auth.init();

    localeManager = LocaleManager();
    localeManager.init();

    notificationManager = NotificationManager();
    notificationManager.init();

    themeManager = ThemeManager();
    themeManager.init();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([themeManager, localeManager, notificationManager]),
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Sfinity',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeManager.themeMode,
          locale: localeManager.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        );
      },
    );
  }
}
