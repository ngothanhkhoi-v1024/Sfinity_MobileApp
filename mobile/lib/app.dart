import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_repository.dart';
import 'core/auth/auth_state.dart';
import 'core/router/app_router.dart';
import 'core/services/theme_manager.dart';
import 'core/theme/app_theme.dart';

class SfinityApp extends StatefulWidget {
  const SfinityApp({super.key});

  static AuthState get auth => _SfinityAppState.auth;
  static ThemeManager get themeManager => _SfinityAppState.themeManager;

  @override
  State<SfinityApp> createState() => _SfinityAppState();
}

class _SfinityAppState extends State<SfinityApp> {
  static late final AuthState auth;
  static late final ThemeManager themeManager;
  late final GoRouter _router = createAppRouter(auth);

  @override
  void initState() {
    super.initState();
    auth = AuthState(AuthRepository());
    auth.init();

    themeManager = ThemeManager();
    themeManager.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Sfinity',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeManager.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}
