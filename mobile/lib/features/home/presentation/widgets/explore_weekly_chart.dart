import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class ExploreWeeklyChart extends StatelessWidget {
  const ExploreWeeklyChart({
    super.key,
    this.compact = false,
    required this.days,
    required this.totalPlaces,
    required this.totalDownloads,
  });

  final bool compact;
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

    final radius = compact ? 14.0 : 18.0;
    final chartHeight = compact ? 56.0 : 120.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
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
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: _accent.withValues(alpha: isDark ? 0.1 : 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      padding: EdgeInsets.fromLTRB(compact ? 10 : 16, compact ? 8 : 16, compact ? 10 : 16, compact ? 8 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact)
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
          if (!compact) const SizedBox(height: 14),
          Row(
            children: [
              _SummaryPill(
                compact: compact,
                icon: Icons.location_on_outlined,
                label: l10n.weeklyPlacesVisited,
                value: '$totalPlaces',
                color: _accentDeep,
              ),
              SizedBox(width: compact ? 8 : 10),
              _SummaryPill(
                compact: compact,
                icon: Icons.file_download_outlined,
                label: l10n.weeklyDocsDownloaded,
                value: '$totalDownloads',
                color: _docColor,
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 18),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days)
                  Expanded(
                    child: _DayBars(
                      compact: compact,
                      label: day['label']?.toString() ?? '',
                      places: (day['places'] as num?)?.toInt() ?? 0,
                      downloads: (day['downloads'] as num?)?.toInt() ?? 0,
                      maxValue: chartMax,
                    ),
                  ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _LegendDot(color: _accentDeep, label: l10n.places),
                const SizedBox(width: 14),
                _LegendDot(color: _docColor, label: l10n.documents),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: _accentDeep, label: l10n.places, compact: true),
                const SizedBox(width: 12),
                _LegendDot(color: _docColor, label: l10n.documents, compact: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    this.compact = false,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: compact ? 5 : 10,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: compact ? 14 : 16, color: color),
            SizedBox(width: compact ? 4 : 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title(context),
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 9 : 10,
                      color: AppColors.muted(context),
                    ),
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
    this.compact = false,
    required this.label,
    required this.places,
    required this.downloads,
    required this.maxValue,
  });

  final bool compact;
  final String label;
  final int places;
  final int downloads;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final maxBarHeight = compact ? 36.0 : 72.0;

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
        SizedBox(height: compact ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 9 : 10,
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
  const _LegendDot({
    required this.color,
    required this.label,
    this.compact = false,
  });

  final Color color;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 6 : 8,
          height: compact ? 6 : 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: compact ? 4 : 5),
        Text(
          label,
          style: TextStyle(fontSize: compact ? 9 : 11, color: AppColors.muted(context)),
        ),
      ],
    );
  }
}
