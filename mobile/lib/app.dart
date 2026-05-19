import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_shell_page.dart';

/// Entry widget — routing sẽ chuyển sang GoRouter sau.
class SfinityApp extends StatelessWidget {
  const SfinityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sfinity',
      theme: AppTheme.light,
      home: const HomeShellPage(),
    );
  }
}
