import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Ô tìm kiếm — style đồng bộ các tab chính.
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
    final primary = AppColors.primaryOf(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;

        return SizedBox(
          height: _height,
          child: TextField(
            controller: controller,
            style: TextStyle(fontSize: 15, color: AppColors.title(context)),
            cursorColor: primary,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: AppColors.muted(context)),
              filled: true,
              fillColor: AppColors.searchFill(context),
              prefixIcon: Icon(Icons.search_rounded, size: 22, color: primary),
              suffixIcon: hasText
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: AppColors.muted(context)),
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
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border(context)),
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
