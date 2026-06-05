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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.chipBg(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  _TabChip(
                    item: tabs[i],
                    selected: controller.index == i,
                    primary: primary,
                    onTap: () => onTap(i),
                  ),
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
    required this.onTap,
  });

  final CommunityTabItem item;
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? primary : AppColors.muted(context),
                ),
              ),
              if (item.badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: 0.12)
                        : AppColors.border(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.badgeCount}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? primary : AppColors.muted(context),
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
