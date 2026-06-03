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
    final isDark = AppColors.isDark(context);
    final l10n = context.l10n;

    return Padding(
      padding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: compact ? 44 : 50,
        decoration: BoxDecoration(
          color: AppColors.toggleTrack(context),
          borderRadius: BorderRadius.circular(compact ? 12 : 25),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double tabWidth = width / 2;

            return Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  alignment: communityMode
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: tabWidth - 4,
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandPill(context),
                      borderRadius: BorderRadius.circular(compact ? 10 : 22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOf(context).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(true),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.public_outlined,
                                size: 18,
                                color: communityMode
                                    ? Colors.white
                                    : AppColors.muted(context),
                              ),
                              const SizedBox(width: 8),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: communityMode
                                      ? Colors.white
                                      : AppColors.muted(context),
                                  fontWeight: communityMode
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                                child: Text(l10n.explore),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(false),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_pin_outlined,
                                size: 18,
                                color: !communityMode
                                    ? Colors.white
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                              const SizedBox(width: 8),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: !communityMode
                                      ? Colors.white
                                      : AppColors.muted(context),
                                  fontWeight: !communityMode
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                                child: Text(l10n.yourUploadedDocuments),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
