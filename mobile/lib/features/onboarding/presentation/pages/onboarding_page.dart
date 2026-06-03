import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';

class _OnboardingSlide {
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) badge;
  final String Function(AppLocalizations) description;
  final IconData icon;

  const _OnboardingSlide({
    required this.title,
    required this.badge,
    required this.description,
    required this.icon,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static final _slides = [
    _OnboardingSlide(
      title: (l) => l.welcomeTitle,
      badge: (l) => l.welcomeBadge,
      description: (l) => l.welcomeDescription,
      icon: Icons.rocket_launch_rounded,
    ),
    _OnboardingSlide(
      title: (l) => l.smartSearchTitle,
      badge: (l) => l.smartSearchBadge,
      description: (l) => l.smartSearchDescription,
      icon: Icons.manage_search_rounded,
    ),
    _OnboardingSlide(
      title: (l) => l.stayConnectedTitle,
      badge: (l) => l.stayConnectedBadge,
      description: (l) => l.stayConnectedDescription,
      icon: Icons.devices_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _animController
      ..reset()
      ..forward();
  }

  void _nextPage() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  // Skip button
                  AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: isLast ? null : () => context.go(RouteNames.login),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      child: Text(l10n.skip),
                    ),
                  ),
                ],
              ),
            ),

            // ── Page view ────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, i) => _SlideView(
                  slide: _slides[i],
                  l10n: l10n,
                  fadeAnim: _fadeAnim,
                  slideAnim: _slideAnim,
                ),
              ),
            ),

            // ── Indicators ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active
                          ? colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
            ),

            // ── Button ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: FilledButton(
                onPressed: _nextPage,
                child: Text(isLast ? l10n.getStartedNow : l10n.next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  const _SlideView({
    super.key,
    required this.slide,
    required this.l10n,
    required this.fadeAnim,
    required this.slideAnim,
  });

  final _OnboardingSlide slide;
  final AppLocalizations l10n;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon với layered circles
              _AnimatedIcon(icon: slide.icon, color: primary),

              const SizedBox(height: 44),

              // Title
              Text(
                slide.title(l10n),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Badge pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  slide.badge(l10n),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                slide.description(l10n),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedIcon extends StatefulWidget {
  const _AnimatedIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.06),
              ),
            ),
            // Middle ring
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.10),
              ),
            ),
            // Inner filled circle
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.15),
              ),
              child: Icon(
                widget.icon,
                size: 36,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}