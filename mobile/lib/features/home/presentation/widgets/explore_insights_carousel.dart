import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import 'explore_featured_section.dart';
import 'explore_top_users_section.dart';
import 'explore_weekly_chart.dart';

/// Gộp Nổi bật / Hoạt động tuần / Top users vào một panel có tab — giảm chiều dọc.
class ExploreInsightsCarousel extends StatefulWidget {
  const ExploreInsightsCarousel({
    super.key,
    required this.trendingPlaces,
    required this.trendingDocuments,
    required this.weeklyDays,
    required this.totalPlaces,
    required this.totalDownloads,
    required this.topUsers,
    required this.onPlaceTap,
    required this.onDocumentTap,
    required this.onUserTap,
  });

  final List<Map<String, dynamic>> trendingPlaces;
  final List<Map<String, dynamic>> trendingDocuments;
  final List<Map<String, dynamic>> weeklyDays;
  final int totalPlaces;
  final int totalDownloads;
  final List<Map<String, dynamic>> topUsers;
  final ValueChanged<Map<String, dynamic>> onPlaceTap;
  final ValueChanged<Map<String, dynamic>> onDocumentTap;
  final ValueChanged<Map<String, dynamic>> onUserTap;

  static const _featuredHeight = 124.0;
  static const _weeklyHeight = 158.0;
  static const _rankHeight = 156.0;

  @override
  State<ExploreInsightsCarousel> createState() => _ExploreInsightsCarouselState();
}

class _ExploreInsightsCarouselState extends State<ExploreInsightsCarousel> {
  int _tab = 0;

  bool get _hasFeatured =>
      widget.trendingPlaces.isNotEmpty || widget.trendingDocuments.isNotEmpty;

  bool get _hasWeekly => widget.weeklyDays.isNotEmpty;

  bool get _hasTopUsers => widget.topUsers.isNotEmpty;

  double get _contentHeight => switch (_tab) {
        1 => ExploreInsightsCarousel._weeklyHeight,
        2 => ExploreInsightsCarousel._rankHeight,
        _ => ExploreInsightsCarousel._featuredHeight,
      };

  @override
  void initState() {
    super.initState();
    _tab = _firstAvailableTab();
  }

  int _firstAvailableTab() {
    if (_hasFeatured) return 0;
    if (_hasWeekly) return 1;
    if (_hasTopUsers) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasFeatured && !_hasWeekly && !_hasTopUsers) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    final tabs = <(int, String, IconData, bool)>[
      (0, l10n.featuredHighlights, Icons.local_fire_department_rounded, _hasFeatured),
      (1, l10n.insightsTabWeek, Icons.bar_chart_rounded, _hasWeekly),
      (2, l10n.insightsTabRank, Icons.emoji_events_rounded, _hasTopUsers),
    ].where((t) => t.$4).toList();

    if (!tabs.any((t) => t.$1 == _tab)) {
      _tab = tabs.first.$1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.chipBg(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                for (final (index, label, icon, _) in tabs)
                  Expanded(
                    child: _InsightTab(
                      label: label,
                      icon: icon,
                      selected: _tab == index,
                      primary: primary,
                      onTap: () => setState(() => _tab = index),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: _contentHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (_tab) {
                0 => ExploreFeaturedSection(
                    key: const ValueKey('featured'),
                    compact: true,
                    trendingPlaces: widget.trendingPlaces,
                    trendingDocuments: widget.trendingDocuments,
                    onPlaceTap: widget.onPlaceTap,
                    onDocumentTap: widget.onDocumentTap,
                  ),
                1 => ExploreWeeklyChart(
                    key: const ValueKey('weekly'),
                    compact: true,
                    days: widget.weeklyDays,
                    totalPlaces: widget.totalPlaces,
                    totalDownloads: widget.totalDownloads,
                  ),
                _ => ExploreTopUsersSection(
                    key: const ValueKey('top'),
                    compact: true,
                    users: widget.topUsers,
                    onUserTap: widget.onUserTap,
                  ),
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightTab extends StatelessWidget {
  const _InsightTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final color = selected ? primary : AppColors.muted(context);

    return Material(
      color: selected
          ? (isDark ? const Color(0xFF2A2A2A) : Colors.white)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: selected && !isDark ? 0.5 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
