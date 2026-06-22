import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/voice_search_suffix.dart';

class PlacesSearchField extends StatelessWidget {
  const PlacesSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.hint,
    this.enableVoiceInput = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hint;
  final bool enableVoiceInput;

  static const _height = 48.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = AppColors.primaryOf(context);
    final effectiveHint = hint ?? l10n.searchPlace;

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
              hintText: effectiveHint,
              hintStyle: TextStyle(fontSize: 14, color: AppColors.muted(context)),
              filled: true,
              fillColor: AppColors.searchFill(context),
              prefixIcon: Icon(Icons.search_rounded, size: 22, color: primary),
              suffixIcon: enableVoiceInput
                  ? VoiceSearchSuffix(
                      controller: controller,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      iconColor: AppColors.muted(context),
                    )
                  : (hasText
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, size: 20, color: AppColors.muted(context)),
                          onPressed: () {
                            controller.clear();
                            onChanged('');
                          },
                          splashRadius: 18,
                        )
                      : null),
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
