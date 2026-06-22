import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class ExploreFeaturedSection extends StatelessWidget {
  const ExploreFeaturedSection({
    super.key,
    this.compact = false,
    required this.trendingPlaces,
    required this.trendingDocuments,
    required this.onPlaceTap,
    required this.onDocumentTap,
  });

  final bool compact;
  final List<Map<String, dynamic>> trendingPlaces;
  final List<Map<String, dynamic>> trendingDocuments;
  final ValueChanged<Map<String, dynamic>> onPlaceTap;
  final ValueChanged<Map<String, dynamic>> onDocumentTap;

  static const _accent = AppColors.secondary;
  static const _accentDeep = Color(0xFFE65100);
  static const _cardHeight = 148.0;
  static const _compactCardHeight = 124.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (trendingPlaces.isEmpty && trendingDocuments.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      final items = <_FeaturedListItem>[
        for (final p in trendingPlaces) _FeaturedListItem(place: true, data: p),
        for (final d in trendingDocuments) _FeaturedListItem(place: false, data: d),
      ];

      return SizedBox(
        height: _compactCardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, index) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final item = items[i];
            if (item.place) {
              return _FeaturedPlaceCard(
                item: item.data,
                compact: true,
                onTap: () => onPlaceTap(item.data),
              );
            }
            return _FeaturedDocumentCard(
              item: item.data,
              compact: true,
              onTap: () => onDocumentTap(item.data),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.featuredHighlights),
        const SizedBox(height: 12),
        if (trendingPlaces.isNotEmpty) ...[
          _SubSectionLabel(
            icon: Icons.local_fire_department_rounded,
            label: l10n.featuredPlaces,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trendingPlaces.length,
              separatorBuilder: (_, index) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _FeaturedPlaceCard(
                item: trendingPlaces[i],
                onTap: () => onPlaceTap(trendingPlaces[i]),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (trendingDocuments.isNotEmpty) ...[
          _SubSectionLabel(
            icon: Icons.trending_up_rounded,
            label: l10n.featuredDocuments,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trendingDocuments.length,
              separatorBuilder: (_, index) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _FeaturedDocumentCard(
                item: trendingDocuments[i],
                onTap: () => onDocumentTap(trendingDocuments[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeaturedListItem {
  const _FeaturedListItem({required this.place, required this.data});

  final bool place;
  final Map<String, dynamic> data;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.title(context),
          ),
    );
  }
}

class _SubSectionLabel extends StatelessWidget {
  const _SubSectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ExploreFeaturedSection._accent),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted(context),
          ),
        ),
      ],
    );
  }
}

class _FeaturedPlaceCard extends StatelessWidget {
  const _FeaturedPlaceCard({
    required this.item,
    required this.onTap,
    this.compact = false,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = (item['recentCheckInCount'] as num?)?.toInt() ?? 0;
    final isRecent = item['isRecentTrend'] == true;
    final title = item['title']?.toString() ?? '';
    final address = item['address']?.toString() ?? '';

    return _FeaturedCardShell(
      onTap: onTap,
      compact: compact,
      icon: Icons.location_on_rounded,
      title: title,
      subtitle: address.isNotEmpty ? address : l10n.places,
      badge: isRecent ? l10n.recentCheckins(count) : l10n.totalCheckins(count),
      badgeIcon: Icons.verified_outlined,
    );
  }
}

class _FeaturedDocumentCard extends StatelessWidget {
  const _FeaturedDocumentCard({
    required this.item,
    required this.onTap,
    this.compact = false,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = (item['downloadsCount'] as num?)?.toInt() ?? 0;
    final title = item['title']?.toString() ?? '';
    final category = (item['category'] as Map?)?['name']?.toString() ?? '';

    return _FeaturedCardShell(
      onTap: onTap,
      compact: compact,
      icon: Icons.article_rounded,
      title: title,
      subtitle: category.isNotEmpty
          ? l10n.translateCategory(category)
          : l10n.documents,
      badge: l10n.popularDownloads(count),
      badgeIcon: Icons.file_download_outlined,
    );
  }
}

class _FeaturedCardShell extends StatelessWidget {
  const _FeaturedCardShell({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeIcon,
    this.compact = false,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final IconData badgeIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardHeight =
        compact ? ExploreFeaturedSection._compactCardHeight : ExploreFeaturedSection._cardHeight;

    return SizedBox(
      width: compact ? 168 : 210,
      height: cardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 14 : 18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF2A1A12), const Color(0xFF1A1A1A)]
                    : [const Color(0xFFFFF7ED), Colors.white],
              ),
              border: Border.all(
                color: ExploreFeaturedSection._accent.withValues(alpha: isDark ? 0.35 : 0.22),
              ),
              boxShadow: compact
                  ? null
                  : [
                      BoxShadow(
                        color: ExploreFeaturedSection._accent
                            .withValues(alpha: isDark ? 0.12 : 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 8 : 12),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    ExploreFeaturedSection._accent,
                                    ExploreFeaturedSection._accentDeep,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, size: 14, color: Colors.white),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.muted(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: AppColors.title(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.muted(context),
                          ),
                        ),
                        const Spacer(),
                        _FeaturedBadge(
                          badge: badge,
                          badgeIcon: badgeIcon,
                          isDark: isDark,
                          compact: true,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    ExploreFeaturedSection._accent,
                                    ExploreFeaturedSection._accentDeep,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, size: 17, color: Colors.white),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.muted(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  color: AppColors.title(context),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _FeaturedBadge(
                          badge: badge,
                          badgeIcon: badgeIcon,
                          isDark: isDark,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge({
    required this.badge,
    required this.badgeIcon,
    required this.isDark,
    this.compact = false,
  });

  final String badge;
  final IconData badgeIcon;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: ExploreFeaturedSection._accent.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: compact ? 10 : 12,
            color: ExploreFeaturedSection._accentDeep,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w700,
                color: ExploreFeaturedSection._accentDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
