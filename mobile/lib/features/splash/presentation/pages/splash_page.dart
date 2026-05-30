import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../widgets/academic_sealion_mascot.dart';

/// Màn hình mở app — animation hải cẩu học thuật rồi chuyển sang onboarding/home.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _exit;
  late final Animation<double> _exitFade;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _exitFade = CurvedAnimation(parent: _exit, curve: Curves.easeIn);

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    await _exit.forward();
    if (!mounted) return;
    _goNext();
  }

  void _goNext() {
    if (_navigated) return;
    _navigated = true;

    final auth = SfinityApp.auth;
    if (auth.isAuthenticated) {
      context.go(RouteNames.home);
    } else {
      context.go(RouteNames.onboarding);
    }
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mascotSize = (screenWidth * 0.72).clamp(280.0, 360.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFBF7),
      body: FadeTransition(
        opacity: ReverseAnimation(_exitFade),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _GlowOrb(
                size: 260,
                color: theme.colorScheme.secondary.withValues(alpha: isDark ? 0.12 : 0.18),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: _GlowOrb(
                size: 220,
                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.14),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  AcademicSealionMascot(size: mascotSize),
                  const SizedBox(height: 24),
                  Text(
                    'Sfinity',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontSize: 32,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Học tập mọi lúc, mọi nơi',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
