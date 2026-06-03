import 'package:flutter/material.dart';

/// Kiểu marker trên bản đồ — nhận diện thương hiệu Sfinity.
enum PlaceMapPinVariant {
  /// Địa điểm cộng đồng (mặc định).
  community,

  /// Đã lưu (bookmark) hoặc tab Của tôi.
  saved,

  /// Đang chọn — địa điểm cộng đồng.
  highlightedCommunity,

  /// Đang chọn — địa điểm đã lưu.
  highlightedSaved,
}

/// Pin tùy chỉnh thay cho `Icons.place` mặc định.
class PlaceMapPin extends StatelessWidget {
  const PlaceMapPin({
    super.key,
    required this.variant,
    this.size = 40,
  });

  final PlaceMapPinVariant variant;
  final double size;

  static const _primary = Color(0xFFE53935);
  static const _saved = Color(0xFFF59E0B);
  static const _highlight = Color(0xFFFF6F00);

  @override
  Widget build(BuildContext context) {
    final (color, icon, ring) = switch (variant) {
      PlaceMapPinVariant.community => (_primary, Icons.school_rounded, false),
      PlaceMapPinVariant.saved => (_saved, Icons.bookmark_rounded, false),
      PlaceMapPinVariant.highlightedCommunity => (_highlight, Icons.school_rounded, true),
      PlaceMapPinVariant.highlightedSaved => (_highlight, Icons.bookmark_rounded, true),
    };

    final head = size * 0.72;
    final tail = size * 0.28;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          if (ring)
            Positioned(
              top: -4,
              child: Container(
                width: head + 12,
                height: head + 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _highlight, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _highlight.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: head,
                height: head,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: head * 0.48),
              ),
              CustomPaint(
                size: Size(tail * 1.4, tail),
                painter: _PinTailPainter(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) => oldDelegate.color != color;
}
