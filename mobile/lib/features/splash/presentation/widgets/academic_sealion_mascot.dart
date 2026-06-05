import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hải cẩu học thuật — đọc sách, gật đầu, lật trang, vẫy vây.
class AcademicSealionMascot extends StatefulWidget {
  const AcademicSealionMascot({super.key, this.size = 220});

  final double size;

  @override
  State<AcademicSealionMascot> createState() => _AcademicSealionMascotState();
}

class _AcademicSealionMascotState extends State<AcademicSealionMascot>
    with TickerProviderStateMixin {
  late final AnimationController _loop;
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _loop.dispose();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return AnimatedBuilder(
      animation: Listenable.merge([_loop, _entry]),
      builder: (context, _) {
        final t = _loop.value;
        final entry = Curves.easeOutCubic.transform(_entry.value);

        return Transform.scale(
          scale: 0.86 + entry * 0.14,
          alignment: Alignment.center,
          child: Opacity(
            opacity: Curves.easeOutCubic.transform(_entry.value.clamp(0.0, 1.0)),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _AcademicSealionPainter(
                  bob: math.sin(t * math.pi * 2) * 3.5,
                  headNod: math.sin(t * math.pi * 2 + 0.4) * 0.05,
                  pageTurn: (math.sin(t * math.pi * 2 - 0.2) + 1) / 2,
                  flipperWave: math.sin(t * math.pi * 2 + 1.2) * 0.22,
                  blink: t > 0.84 && t < 0.9 ? 1.0 : 0.0,
                  orbit: t * math.pi * 2,
                  primary: primary,
                  secondary: secondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AcademicSealionPainter extends CustomPainter {
  _AcademicSealionPainter({
    required this.bob,
    required this.headNod,
    required this.pageTurn,
    required this.flipperWave,
    required this.blink,
    required this.orbit,
    required this.primary,
    required this.secondary,
  });

  static const _baseSize = 220.0;
  static const _contentBounds = Rect.fromLTRB(-92, -106, 92, 64);

  final double bob;
  final double headNod;
  final double pageTurn;
  final double flipperWave;
  final double blink;
  final double orbit;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _baseSize;
    final contentCenter = _contentBounds.center;

    canvas.save();
    canvas.translate(
      size.width / 2 - contentCenter.dx * scale,
      size.height / 2 + bob * scale - contentCenter.dy * scale,
    );
    canvas.scale(scale);

    _drawOrbitIcons(canvas);
    _drawBody(canvas);
    _drawFlippers(canvas);
    _drawBook(canvas);
    _drawHead(canvas);
    _drawGraduationCap(canvas);

    canvas.restore();
  }

  void _drawOrbitIcons(Canvas canvas) {
    const icons = [
      Icons.menu_book_rounded,
      Icons.location_on_rounded,
      Icons.edit_note_rounded,
    ];
    const radius = _baseSize * 0.42;

    for (var i = 0; i < icons.length; i++) {
      final angle = orbit + i * (math.pi * 2 / 3);
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius * 0.55 - 8;
      final pulse = 0.55 + 0.45 * math.sin(orbit * 2 + i);

      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icons[i].codePoint),
          style: TextStyle(
            fontSize: 18 + pulse * 4,
            fontFamily: icons[i].fontFamily,
            package: icons[i].fontPackage,
            color: primary.withValues(alpha: 0.12 + pulse * 0.16),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  void _drawBody(Canvas canvas) {
    final bodyRect = Rect.fromCenter(
      center: const Offset(0, 28),
      width: 118,
      height: 72,
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [secondary, primary],
      ).createShader(bodyRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(36)),
      bodyPaint,
    );

    final belly = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 34), width: 56, height: 38),
      belly,
    );
  }

  void _drawFlippers(Canvas canvas) {
    final flipperPaint = Paint()..color = primary.withValues(alpha: 0.92);

    canvas.save();
    canvas.translate(-52, 18);
    canvas.rotate(-0.35 + flipperWave * 0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 34, 18),
        const Radius.circular(10),
      ),
      flipperPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(24, 14);
    canvas.rotate(0.25 - flipperWave * 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 36, 20),
        const Radius.circular(10),
      ),
      flipperPaint,
    );
    canvas.restore();
  }

  void _drawBook(Canvas canvas) {
    canvas.save();
    canvas.translate(-8, 8);
    canvas.rotate(-0.08);

    final cover = Paint()..color = const Color(0xFF2D3748);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 58, height: 44),
        const Radius.circular(4),
      ),
      cover,
    );

    final pageBase = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(2, 0), width: 50, height: 38),
        const Radius.circular(2),
      ),
      pageBase,
    );

    final pageTurnAngle = -0.05 - pageTurn * 0.55;
    canvas.save();
    canvas.translate(18, -18);
    canvas.rotate(pageTurnAngle);
    final turningPage = Paint()..color = const Color(0xFFF7FAFC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 24, 36),
        const Radius.circular(2),
      ),
      turningPage,
    );
    canvas.restore();

    final linePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(-16, -8 + i * 7.0),
        Offset(12, -8 + i * 7.0),
        linePaint,
      );
    }

    canvas.restore();
  }

  void _drawHead(Canvas canvas) {
    canvas.save();
    canvas.translate(0, -34);
    canvas.rotate(headNod);

    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [secondary, primary],
        center: const Alignment(-0.2, -0.3),
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 42));

    canvas.drawCircle(const Offset(0, 0), 40, headPaint);

    final muzzle = Paint()..color = Colors.white.withValues(alpha: 0.88);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 10), width: 34, height: 26),
      muzzle,
    );

    _drawEye(canvas, const Offset(-14, -4), blink);
    _drawEye(canvas, const Offset(14, -4), blink);

    final nose = Paint()..color = const Color(0xFF1A202C);
    canvas.drawCircle(const Offset(0, 8), 3.2, nose);

    final whisker = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = -1.0; i <= 1.0; i += 1.0) {
      canvas.drawLine(Offset(-8, 12 + i * 3), Offset(-22, 10 + i * 5), whisker);
      canvas.drawLine(Offset(8, 12 + i * 3), Offset(22, 10 + i * 5), whisker);
    }

    _drawGlasses(canvas);

    canvas.restore();
  }

  void _drawEye(Canvas canvas, Offset center, double blinkAmount) {
    final white = Paint()..color = Colors.white;
    canvas.drawCircle(center, 7.5, white);

    if (blinkAmount > 0.3) {
      final lid = Paint()..color = primary;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 7.5),
        math.pi,
        math.pi,
        true,
        lid,
      );
      return;
    }

    final pupil = Paint()..color = const Color(0xFF1A202C);
    canvas.drawCircle(center + const Offset(1.5, 1), 3.2, pupil);
    canvas.drawCircle(center + const Offset(3, -1.5), 1.2, Paint()..color = Colors.white);
  }

  void _drawGlasses(Canvas canvas) {
    final frame = Paint()
      ..color = const Color(0xFF1A202C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-14, -4), width: 22, height: 18),
        const Radius.circular(6),
      ),
      frame,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(14, -4), width: 22, height: 18),
        const Radius.circular(6),
      ),
      frame,
    );
    canvas.drawLine(const Offset(-3, -4), const Offset(3, -4), frame);
  }

  void _drawGraduationCap(Canvas canvas) {
    canvas.save();
    canvas.translate(0, -58);
    canvas.rotate(-0.12 + headNod * 0.5);

    final cap = Paint()..color = const Color(0xFF1A202C);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 52, height: 8), cap);

    final top = Path()
      ..moveTo(-30, 0)
      ..lineTo(0, -14)
      ..lineTo(30, 0)
      ..close();
    canvas.drawPath(top, cap);

    final tassel = Paint()
      ..color = secondary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(24, -2), const Offset(30, 12), tassel);
    canvas.drawCircle(const Offset(30, 12), 3, Paint()..color = secondary);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AcademicSealionPainter oldDelegate) {
    return bob != oldDelegate.bob ||
        headNod != oldDelegate.headNod ||
        pageTurn != oldDelegate.pageTurn ||
        flipperWave != oldDelegate.flipperWave ||
        blink != oldDelegate.blink ||
        orbit != oldDelegate.orbit;
  }
}
