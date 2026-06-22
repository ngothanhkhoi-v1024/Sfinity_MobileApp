import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class ExploreFeedSectionHeader extends StatelessWidget {
  const ExploreFeedSectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.showingSaved,
    required this.placeCount,
    required this.docCount,
  });

  final String title;
  final int count;
  final bool showingSaved;
  final int placeCount;
  final int docCount;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        if (showingSaved)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(Icons.bookmark_rounded, size: 18, color: primary),
          ),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.title(context),
              ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ),
        ],
        const Spacer(),
        _StatChip(
          icon: Icons.location_on_outlined,
          value: placeCount,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 6),
        _StatChip(
          icon: Icons.article_outlined,
          value: docCount,
          color: AppColors.title(context),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBg(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ExploreFeedCard extends StatelessWidget {
  const ExploreFeedCard({
    super.key,
    required this.item,
    required this.isPlace,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final bool isPlace;
  final VoidCallback onTap;

  static const _placeAccent = AppColors.secondary;
  static const _placeAccentDeep = Color(0xFFE65100);
  static const _docAccent = Color(0xFFFF8A50);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = item['title']?.toString() ?? '';
    final subtitle = _subtitle(l10n);
    final typeLabel = isPlace ? l10n.places : l10n.documents;
    final thumbnailUrl = _thumbnailUrl;
    final isDark = AppColors.isDark(context);

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border(context)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TypeStripe(isPlace: isPlace),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                    child: Row(
                      children: [
                        _FeedThumbnail(
                          isPlace: isPlace,
                          thumbnailUrl: thumbnailUrl,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.25,
                                  letterSpacing: -0.2,
                                  color: AppColors.title(context),
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
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
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isPlace ? _placeAccent : _docAccent)
                                      .withValues(alpha: isDark ? 0.18 : 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isPlace ? _placeAccentDeep : _placeAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.muted(context).withValues(alpha: 0.7),
                        ),
                      ],
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

  String? get _thumbnailUrl {
    final url = item['thumbnailUrl']?.toString().trim() ??
        item['previewImageUrl']?.toString().trim() ??
        '';
    return url.isEmpty ? null : url;
  }

  String _subtitle(AppLocalizations l10n) {
    if (isPlace) {
      final address = item['address']?.toString().trim() ?? '';
      return address.isNotEmpty ? address : l10n.places;
    }

    final parts = <String>[];
    final category = (item['category'] as Map?)?['name']?.toString().trim();
    if (category != null && category.isNotEmpty) {
      parts.add(l10n.translateCategory(category));
    }
    final author = (item['author'] as Map?)?['name']?.toString().trim();
    if (author != null && author.isNotEmpty) {
      parts.add(author);
    }
    final downloads = (item['downloadsCount'] as num?)?.toInt() ?? 0;
    if (downloads > 0) {
      parts.add(l10n.popularDownloads(downloads));
    }
    return parts.join(' · ');
  }
}

class _TypeStripe extends StatelessWidget {
  const _TypeStripe({required this.isPlace});

  final bool isPlace;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isPlace
              ? [ExploreFeedCard._placeAccent, ExploreFeedCard._placeAccentDeep]
              : [ExploreFeedCard._docAccent, ExploreFeedCard._placeAccent],
        ),
      ),
    );
  }
}

class _FeedThumbnail extends StatelessWidget {
  const _FeedThumbnail({
    required this.isPlace,
    required this.thumbnailUrl,
  });

  final bool isPlace;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final colors = isPlace
        ? [ExploreFeedCard._placeAccent, ExploreFeedCard._placeAccentDeep]
        : [ExploreFeedCard._placeAccent.withValues(alpha: 0.85), ExploreFeedCard._docAccent];

    if (thumbnailUrl != null && !isPlace) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          thumbnailUrl!,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => _iconBox(colors, isPlace),
        ),
      );
    }

    return _iconBox(colors, isPlace);
  }

  Widget _iconBox(List<Color> colors, bool isPlace) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        isPlace ? Icons.location_on_rounded : Icons.article_rounded,
        size: 22,
        color: Colors.white,
      ),
    );
  }
}
