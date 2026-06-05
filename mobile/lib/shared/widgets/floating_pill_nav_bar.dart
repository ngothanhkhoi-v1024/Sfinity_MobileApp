import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PillNavItem {
  const PillNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Thanh điều hướng dưới — tối giản, đồng bộ tone Khám phá / Cá nhân.
class FloatingPillNavBar extends StatelessWidget {
  const FloatingPillNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.items,
    @Deprecated('Không còn dùng nút giữa. Bỏ qua.') VoidCallback? onCenterTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<PillNavItem> items;

  static const centerSlotIndex = -1;

  static const _barHeight = 64.0;
  static const _slideDuration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryOf(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count = items.length;
            final cellWidth = constraints.maxWidth / count;
            const inset = 4.0;
            final indicatorWidth = cellWidth - inset * 2;
            final indicatorHeight = constraints.maxHeight - inset * 2;
            final indicatorLeft = cellWidth * selectedIndex + inset;

            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                AnimatedPositioned(
                  duration: _slideDuration,
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  top: inset,
                  width: indicatorWidth,
                  height: indicatorHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primary.withValues(alpha: isDark ? 0.28 : 0.18),
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    count,
                    (i) => _TabButton(
                      item: items[i],
                      selected: selectedIndex == i,
                      primary: primary,
                      onTap: () => onTabSelected(i),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final PillNavItem item;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? primary : AppColors.muted(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: primary.withValues(alpha: 0.06),
          highlightColor: primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
