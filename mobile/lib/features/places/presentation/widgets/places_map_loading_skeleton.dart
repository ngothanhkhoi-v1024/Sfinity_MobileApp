import 'package:flutter/material.dart';

/// Skeleton loading cho map và danh sách địa điểm.
class PlacesMapLoadingSkeleton extends StatefulWidget {
  const PlacesMapLoadingSkeleton({super.key, this.listMode = false});

  final bool listMode;

  @override
  State<PlacesMapLoadingSkeleton> createState() => _PlacesMapLoadingSkeletonState();
}

class _PlacesMapLoadingSkeletonState extends State<PlacesMapLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listMode) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: 6,
        itemBuilder: (context, index) => _ListTileSkeleton(pulse: _pulse),
      );
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final opacity = 0.35 + _pulse.value * 0.25;
        return IgnorePointer(
          child: Container(
            color: Colors.black.withValues(alpha: 0.04),
            child: Stack(
              children: [
                Positioned(
                  left: 24,
                  top: 180,
                  child: _MapPinSkeleton(opacity: opacity, size: 36),
                ),
                Positioned(
                  right: 48,
                  top: 240,
                  child: _MapPinSkeleton(opacity: opacity, size: 44),
                ),
                Positioned(
                  left: MediaQuery.sizeOf(context).width * 0.35,
                  top: 320,
                  child: _MapPinSkeleton(opacity: opacity, size: 52),
                ),
                Positioned(
                  right: 80,
                  bottom: 180,
                  child: _MapPinSkeleton(opacity: opacity, size: 40),
                ),
                Positioned(
                  left: 60,
                  bottom: 220,
                  child: _MapPinSkeleton(opacity: opacity, size: 32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapPinSkeleton extends StatelessWidget {
  const _MapPinSkeleton({required this.opacity, required this.size});

  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white : Colors.black;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: base.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: size * 0.5,
            height: 6,
            decoration: BoxDecoration(
              color: base.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListTileSkeleton extends StatelessWidget {
  const _ListTileSkeleton({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white : Colors.black;
    final opacity = 0.35 + pulse.value * 0.25;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: base.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: base.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 140,
                    decoration: BoxDecoration(
                      color: base.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
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
