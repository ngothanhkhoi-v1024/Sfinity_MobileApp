import 'package:flutter/material.dart';

/// Kiểu marker trên bản đồ — nhận diện thương hiệu Sfinity.
enum PlaceMapPinVariant {
  /// Địa điểm cộng đồng (mặc định).
  community,

  /// Đã lưu (bookmark) hoặc tab Của tôi.
  saved,

  /// Đang chọn / xem chi tiết — cộng đồng.
  highlightedCommunity,

  /// Đang chọn / xem chi tiết — đã lưu.
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

  static const communityColor = Color(0xFFE53935);
  static const savedColor = Color(0xFFF59E0B);

  /// Xanh lá — địa điểm đang được chọn / xem chi tiết.
  static const selectedColor = Color(0xFF22C55E);

  bool get _isSelected => switch (variant) {
        PlaceMapPinVariant.highlightedCommunity ||
        PlaceMapPinVariant.highlightedSaved =>
          true,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (variant) {
      PlaceMapPinVariant.community => (communityColor, Icons.location_on_rounded),
      PlaceMapPinVariant.saved => (savedColor, Icons.bookmark_rounded),
      PlaceMapPinVariant.highlightedCommunity => (selectedColor, Icons.location_on_rounded),
      PlaceMapPinVariant.highlightedSaved => (selectedColor, Icons.location_on_rounded),
    };

    final head = size * 0.68;
    final tail = size * 0.32;
    final ringColor = _isSelected ? selectedColor : color;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          if (_isSelected)
            Positioned(
              top: -2,
              child: Container(
                width: head + 14,
                height: head + 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selectedColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.45),
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
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: ringColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: head * 0.5),
              ),
              CustomPaint(
                size: Size(tail * 1.5, tail),
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
