import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_state.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/services/auth_api_service.dart';
import 'features/auth/data/services/auth_local_database.dart';
import 'features/auth/data/services/firebase_auth_service.dart';
import 'features/auth/data/services/firestore_user_service.dart';
import 'features/auth/data/services/social_auth_service.dart';

class SfinityApp extends StatefulWidget {
  const SfinityApp({super.key});

  static AuthState get auth => _SfinityAppState.auth;

  @override
  State<SfinityApp> createState() => _SfinityAppState();
}

class _SfinityAppState extends State<SfinityApp> {
  static late final AuthState auth;
  late final GoRouter _router = createAppRouter(auth);

  @override
  void initState() {
    super.initState();
    final apiService = AuthApiService(ApiClient.instance);
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sfinity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
