import 'package:flutter/material.dart';

import 'place_map_pin.dart';

/// Pin với vòng pulse khi địa điểm đang được focus.
class AnimatedPlaceMapPin extends StatefulWidget {
  const AnimatedPlaceMapPin({
    super.key,
    required this.variant,
    required this.size,
    this.pulse = false,
  });

  final PlaceMapPinVariant variant;
  final double size;
  final bool pulse;

  @override
  State<AnimatedPlaceMapPin> createState() => _AnimatedPlaceMapPinState();
}

class _AnimatedPlaceMapPinState extends State<AnimatedPlaceMapPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(AnimatedPlaceMapPin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) _syncPulse();
  }

  void _syncPulse() {
    if (widget.pulse) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) {
      return PlaceMapPin(variant: widget.variant, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final scale = 1.0 + (0.12 * (1 - (2 * t - 1).abs()));
        final ringOpacity = (1 - t) * 0.55;

        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: widget.size * 0.05,
              child: Transform.scale(
                scale: 1.0 + t * 0.85,
                child: Container(
                  width: widget.size * 0.78,
                  height: widget.size * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: PlaceMapPin.selectedColor.withValues(alpha: ringOpacity),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),
            Transform.scale(scale: scale, child: child),
          ],
        );
      },
      child: PlaceMapPin(variant: widget.variant, size: widget.size),
    );
  }
}
