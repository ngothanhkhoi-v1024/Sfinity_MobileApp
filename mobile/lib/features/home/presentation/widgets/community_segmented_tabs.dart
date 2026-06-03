import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CommunityTabItem {
  const CommunityTabItem({
    required this.label,
    required this.icon,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final int badgeCount;
}

/// Tab chuyển gọn cho màn Cộng đồng.
class CommunitySegmentedTabs extends StatelessWidget {
  const CommunitySegmentedTabs({
    super.key,
    required this.controller,
    required this.tabs,
    required this.onTap,
  });

  final TabController controller;
  final List<CommunityTabItem> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.toggleTrack(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _TabChip(
                    item: tabs[i],
                    selected: controller.index == i,
                    primary: primary,
                    isDark: AppColors.isDark(context),
                    onTap: () => onTap(i),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.item,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final CommunityTabItem item;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? (isDark ? primary.withValues(alpha: 0.25) : Colors.white)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 16,
                color: selected
                    ? primary
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? (isDark ? Colors.white : const Color(0xFF1F2937))
                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                ),
              ),
              if (item.badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? primary : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.badgeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
