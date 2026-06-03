import 'package:flutter/material.dart';

/// Màu và token UI dùng chung — Khám phá, Địa điểm, Tài liệu, Cộng đồng, Cá nhân.
abstract final class AppColors {
  static const primary = Color(0xFFE53935);
  static const secondary = Color(0xFFFF5A36);

  static const textLight = Color(0xFF1F2937);
  static const textDark = Color(0xFFF2F2F2);
  static const titleLight = Color(0xFF111827);
  static const titleDark = Color(0xFFF3F4F6);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryOf(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color secondaryOf(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  static Color scaffold(BuildContext context) =>
      isDark(context) ? const Color(0xFF0A0A0A) : Colors.white;

  static Color card(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1A1A) : Colors.white;

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB);

  static Color searchFill(BuildContext context) =>
      isDark(context) ? const Color(0xFF1C1C1C) : const Color(0xFFF9FAFB);

  static Color chipBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF252525) : const Color(0xFFF3F4F6);

  static Color muted(BuildContext context) =>
      isDark(context) ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  static Color subtitle(BuildContext context) => muted(context);

  static Color title(BuildContext context) =>
      isDark(context) ? titleDark : titleLight;

  static Color divider(BuildContext context) =>
      isDark(context) ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6);

  static Color toggleTrack(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6);

  static Color primaryTint(BuildContext context, {double light = 0.1, double dark = 0.18}) {
    final a = isDark(context) ? dark : light;
    return primaryOf(context).withValues(alpha: a);
  }

  static BoxDecoration panel(BuildContext context, {double radius = 16}) {
    return BoxDecoration(
      color: card(context),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border(context)),
    );
  }

  static LinearGradient brandHeader(BuildContext context) {
    final dark = isDark(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryOf(context).withValues(alpha: dark ? 0.35 : 0.12),
        secondaryOf(context).withValues(alpha: dark ? 0.2 : 0.08),
      ],
    );
  }

  static LinearGradient brandPill(BuildContext context) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryOf(context), secondaryOf(context)],
      );
}
