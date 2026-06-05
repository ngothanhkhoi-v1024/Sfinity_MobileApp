import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/academic_sealion_mascot.dart';

/// Màn hình mở app — tone cam Sfinity, animation mượt, học thuật.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _exit;
  late final AnimationController _progress;
  late final Animation<double> _bgFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _ringPulse;
  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _bgFade = CurvedAnimation(parent: _intro, curve: const Interval(0, 0.35, curve: Curves.easeOut));
    _logoFade = CurvedAnimation(parent: _intro, curve: const Interval(0.08, 0.55, curve: Curves.easeOutCubic));
    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.08, 0.62, curve: Curves.easeOutCubic)),
    );
    _ringPulse = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.2, 1, curve: Curves.easeInOut)),
    );
    _titleFade = CurvedAnimation(parent: _intro, curve: const Interval(0.38, 0.78, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.38, 0.78, curve: Curves.easeOutCubic)),
    );
    _taglineFade = CurvedAnimation(parent: _intro, curve: const Interval(0.5, 0.9, curve: Curves.easeOut));

    _exitFade = CurvedAnimation(parent: _exit, curve: Curves.easeInCubic);
    _exitScale = Tween<double>(begin: 1, end: 1.03).animate(
      CurvedAnimation(parent: _exit, curve: Curves.easeInCubic),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    _intro.forward();
    _progress.forward();
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    _goNext();
  }

  void _goNext() {
    if (_navigated) return;
    _navigated = true;
    if (SfinityApp.auth.isAuthenticated) {
      context.go(RouteNames.home);
    } else {
      context.go(RouteNames.onboarding);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _exit.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AppColors.isDark(context);
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final mascotSize = (size.width * 0.52).clamp(200.0, 260.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFBF7),
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _exit]),
        builder: (context, child) {
          final fadeOut = 1 - _exitFade.value;
          return Opacity(
            opacity: fadeOut,
            child: Transform.scale(
              scale: _exitScale.value,
              child: child,
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: _bgFade,
              child: _SplashBackground(isDark: isDark),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _SplashLogoStage(
                        mascotSize: mascotSize,
                        ringPulse: _ringPulse,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: _SplashTitle(isDark: isDark),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'Học tập mọi lúc, mọi nơi',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted(context),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  Padding(
                    padding: EdgeInsets.fromLTRB(48, 0, 48, 20 + bottomInset),
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: _progress.value,
                                minHeight: 3,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.primary.withValues(alpha: 0.12),
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Đang chuẩn bị không gian học tập…',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.muted(context),
                                letterSpacing: 0.15,
                              ),
                            ),
                          ],
                        );
                      },
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

class _SplashLogoStage extends StatelessWidget {
  const _SplashLogoStage({
    required this.mascotSize,
    required this.ringPulse,
    required this.isDark,
  });

  final double mascotSize;
  final Animation<double> ringPulse;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final stageSize = mascotSize + 56;

    return AnimatedBuilder(
      animation: ringPulse,
      builder: (context, child) {
        return Container(
          width: stageSize * ringPulse.value,
          height: stageSize * ringPulse.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.18),
                AppColors.secondary.withValues(alpha: isDark ? 0.22 : 0.14),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF141414) : const Color(0xFFFFFBF7),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.65),
                ),
              ),
              child: ClipOval(child: child),
            ),
          ),
        );
      },
      child: Center(
        child: AcademicSealionMascot(size: mascotSize * 0.92),
      ),
    );
  }
}

class _SplashTitle extends StatelessWidget {
  const _SplashTitle({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.brandPill(context).createShader(bounds),
      child: Text(
        'Sfinity',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              fontSize: 34,
              color: Colors.white,
            ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0A0A0A),
                      const Color(0xFF121010),
                      const Color(0xFF0A0A0A),
                    ]
                  : [
                      const Color(0xFFFFFBF7),
                      const Color(0xFFFFF5EE),
                      const Color(0xFFFFFBF7),
                    ],
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.brandHeader(context),
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -60,
          child: _SoftGlow(size: 220, color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.2)),
        ),
        Positioned(
          top: 120,
          right: -90,
          child: _SoftGlow(size: 200, color: AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.18)),
        ),
        Positioned(
          bottom: -60,
          left: -40,
          child: _SoftGlow(size: 240, color: AppColors.secondary.withValues(alpha: isDark ? 0.1 : 0.14)),
        ),
        Positioned(
          bottom: 80,
          right: -50,
          child: _SoftGlow(size: 180, color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.12)),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _AcademicGridPainter(isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _AcademicGridPainter extends CustomPainter {
  _AcademicGridPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : AppColors.primary).withValues(alpha: isDark ? 0.03 : 0.04)
      ..strokeWidth = 1;

    const step = 48.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AcademicGridPainter oldDelegate) => false;
}
