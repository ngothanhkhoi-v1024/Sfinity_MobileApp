import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class ExploreFeaturedSection extends StatelessWidget {
  const ExploreFeaturedSection({
    super.key,
    required this.trendingPlaces,
    required this.trendingDocuments,
    required this.onPlaceTap,
    required this.onDocumentTap,
  });

  final List<Map<String, dynamic>> trendingPlaces;
  final List<Map<String, dynamic>> trendingDocuments;
  final ValueChanged<Map<String, dynamic>> onPlaceTap;
  final ValueChanged<Map<String, dynamic>> onDocumentTap;

  static const _accent = AppColors.secondary;
  static const _accentDeep = Color(0xFFE65100);
  static const _cardHeight = 148.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (trendingPlaces.isEmpty && trendingDocuments.isEmpty) {
      return const SizedBox.shrink();
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
  const _FeaturedPlaceCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = (item['recentCheckInCount'] as num?)?.toInt() ?? 0;
    final isRecent = item['isRecentTrend'] == true;
    final title = item['title']?.toString() ?? '';
    final address = item['address']?.toString() ?? '';

    return _FeaturedCardShell(
      onTap: onTap,
      icon: Icons.location_on_rounded,
      title: title,
      subtitle: address.isNotEmpty ? address : l10n.places,
      badge: isRecent ? l10n.recentCheckins(count) : l10n.totalCheckins(count),
      badgeIcon: Icons.verified_outlined,
    );
  }
}

class _FeaturedDocumentCard extends StatelessWidget {
  const _FeaturedDocumentCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = (item['downloadsCount'] as num?)?.toInt() ?? 0;
    final title = item['title']?.toString() ?? '';
    final category = (item['category'] as Map?)?['name']?.toString() ?? '';

    return _FeaturedCardShell(
      onTap: onTap,
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
  });

  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final IconData badgeIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return SizedBox(
      width: 210,
      height: ExploreFeaturedSection._cardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF2A1A12),
                        const Color(0xFF1A1A1A),
                      ]
                    : [
                        const Color(0xFFFFF7ED),
                        Colors.white,
                      ],
              ),
              border: Border.all(
                color: ExploreFeaturedSection._accent.withValues(alpha: isDark ? 0.35 : 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: ExploreFeaturedSection._accent.withValues(alpha: isDark ? 0.12 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ExploreFeaturedSection._accent.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 12, color: ExploreFeaturedSection._accentDeep),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: ExploreFeaturedSection._accentDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
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
