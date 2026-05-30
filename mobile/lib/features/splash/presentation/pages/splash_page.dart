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
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final mascotSize = (size.width * 0.68).clamp(260.0, 340.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFBF7),
      body: FadeTransition(
        opacity: ReverseAnimation(_exitFade),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SplashBackground(isDark: isDark, theme: theme),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AcademicSealionMascot(size: mascotSize),
                    const SizedBox(height: 28),
                    Text(
                      'Sfinity',
                      textAlign: TextAlign.center,
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
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24 + bottomInset,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final secondary = theme.colorScheme.secondary.withValues(alpha: isDark ? 0.1 : 0.16);
    final primary = theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.12);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -100,
          left: -70,
          child: _GlowOrb(size: 240, color: primary),
        ),
        Positioned(
          top: -100,
          right: -70,
          child: _GlowOrb(size: 240, color: secondary),
        ),
        Positioned(
          bottom: -120,
          left: -80,
          child: _GlowOrb(size: 260, color: secondary),
        ),
        Positioned(
          bottom: -120,
          right: -80,
          child: _GlowOrb(size: 260, color: primary),
        ),
      ],
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
