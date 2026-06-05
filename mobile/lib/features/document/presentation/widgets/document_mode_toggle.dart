import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class DocumentModeToggle extends StatelessWidget {
  const DocumentModeToggle({
    super.key,
    required this.communityMode,
    required this.onChanged,
    this.compact = false,
  });

  final bool communityMode;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = AppColors.primaryOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.chipBg(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            Expanded(
              child: _ModeChip(
                label: l10n.community,
                selected: communityMode,
                primary: primary,
                onTap: () => onChanged(true),
              ),
            ),
            Expanded(
              child: _ModeChip(
                label: l10n.personal,
                selected: !communityMode,
                primary: primary,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Material(
      color: selected
          ? (isDark ? const Color(0xFF2A2A2A) : Colors.white)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      elevation: selected && !isDark ? 0.5 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? primary : AppColors.muted(context),
            ),
          ),
        ),
      ),
    );
  }
}
