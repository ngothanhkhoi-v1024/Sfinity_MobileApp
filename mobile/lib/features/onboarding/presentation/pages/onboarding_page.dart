import 'package:flutter/material.dart';

import '../../../../shared/widgets/placeholder_page.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Onboarding',
      subtitle: 'Welcome screens, giới thiệu tính năng, xin quyền',
    );
  }
}
