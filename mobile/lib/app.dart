import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_repository.dart';
import 'core/auth/auth_state.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

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
    auth = AuthState(AuthRepository());
    auth.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sfinity',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
