import 'package:flutter/material.dart';

/// Ô tìm kiếm địa điểm — đồng bộ style tab Khám phá.
class PlacesSearchField extends StatelessWidget {
  const PlacesSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.hint = 'Tìm địa điểm theo tên hoặc địa chỉ…',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hint;

  static const _height = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;

        return SizedBox(
          height: _height,
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
            ),
            cursorColor: primary,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF9FAFB),
              prefixIcon: Icon(Icons.search_rounded, size: 22, color: primary),
              suffixIcon: hasText
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                      ),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      splashRadius: 18,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary.withValues(alpha: 0.55), width: 1.5),
              ),
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        );
      },
    );
  }
}
