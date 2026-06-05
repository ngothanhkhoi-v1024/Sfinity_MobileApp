import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class ExploreWeeklyChart extends StatelessWidget {
  const ExploreWeeklyChart({
    super.key,
    required this.days,
    required this.totalPlaces,
    required this.totalDownloads,
  });

  final List<Map<String, dynamic>> days;
  final int totalPlaces;
  final int totalDownloads;

  static const _accent = AppColors.secondary;
  static const _accentDeep = Color(0xFFE65100);
  static const _docColor = Color(0xFFFF8A50);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);
    final maxValue = days.fold<int>(0, (max, d) {
      final places = (d['places'] as num?)?.toInt() ?? 0;
      final downloads = (d['downloads'] as num?)?.toInt() ?? 0;
      return [max, places, downloads].reduce((a, b) => a > b ? a : b);
    });
    final chartMax = maxValue == 0 ? 1 : maxValue;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A1A12), const Color(0xFF1A1A1A)]
              : [const Color(0xFFFFF7ED), Colors.white],
        ),
        border: Border.all(
          color: _accent.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: isDark ? 0.1 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, _accentDeep],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weeklyActivity,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.title(context),
                      ),
                    ),
                    Text(
                      l10n.weeklyActivitySubtitle,
                      style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryPill(
                icon: Icons.location_on_outlined,
                label: l10n.weeklyPlacesVisited,
                value: '$totalPlaces',
                color: _accentDeep,
              ),
              const SizedBox(width: 10),
              _SummaryPill(
                icon: Icons.file_download_outlined,
                label: l10n.weeklyDocsDownloaded,
                value: '$totalDownloads',
                color: _docColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days) ...[
                  Expanded(
                    child: _DayBars(
                      label: day['label']?.toString() ?? '',
                      places: (day['places'] as num?)?.toInt() ?? 0,
                      downloads: (day['downloads'] as num?)?.toInt() ?? 0,
                      maxValue: chartMax,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LegendDot(color: _accentDeep, label: l10n.places),
              const SizedBox(width: 14),
              _LegendDot(color: _docColor, label: l10n.documents),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title(context),
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: AppColors.muted(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBars extends StatelessWidget {
  const _DayBars({
    required this.label,
    required this.places,
    required this.downloads,
    required this.maxValue,
  });

  final String label;
  final int places;
  final int downloads;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    const maxBarHeight = 72.0;

    double barHeight(int value) =>
        value == 0 ? 4 : (value / maxValue) * maxBarHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(
              height: barHeight(places),
              color: ExploreWeeklyChart._accentDeep,
            ),
            const SizedBox(width: 3),
            _Bar(
              height: barHeight(downloads),
              color: ExploreWeeklyChart._docColor,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.muted(context),
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
        ),
      ],
    );
  }
}
