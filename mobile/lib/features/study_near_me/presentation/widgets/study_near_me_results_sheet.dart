import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/study_near_me_result.dart';

/// Bottom sheet kết quả Học gần tôi.
class StudyNearMeResultsSheet extends StatelessWidget {
  const StudyNearMeResultsSheet({
    super.key,
    required this.result,
    required this.onRetry,
  });

  final StudyNearMeResult result;
  final VoidCallback onRetry;

  static Future<void> show(
    BuildContext context, {
    required StudyNearMeResult result,
    required VoidCallback onRetry,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollController) => StudyNearMeResultsSheet(
          result: result,
          onRetry: onRetry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Học gần tôi',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${result.places.length} địa điểm · ${result.documents.length} tài liệu · trong ${result.radiusKm.toStringAsFixed(0)} km',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Tìm lại',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: result.totalCount == 0
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có địa điểm hoặc tài liệu trong bán kính này.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (result.places.isNotEmpty) ...[
                        _SectionTitle(
                          icon: Icons.place_outlined,
                          title: 'Địa điểm',
                          count: result.places.length,
                        ),
                        ...result.places.map(
                          (p) => _ResultTile(
                            icon: Icons.place_rounded,
                            title: p['title']?.toString() ?? 'Địa điểm',
                            subtitle: _distanceLabel(p),
                            onTap: () {
                              final id = p['id']?.toString();
                              if (id == null || id.isEmpty) return;
                              Navigator.pop(context);
                              context.push('/places/$id');
                            },
                          ),
                        ),
                      ],
                      if (result.documents.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _SectionTitle(
                          icon: Icons.menu_book_outlined,
                          title: 'Tài liệu',
                          count: result.documents.length,
                        ),
                        ...result.documents.map(
                          (d) => _ResultTile(
                            icon: Icons.description_outlined,
                            title: d['title']?.toString() ?? 'Tài liệu',
                            subtitle: _distanceLabel(d),
                            onTap: () {
                              final id = d['id']?.toString();
                              if (id == null || id.isEmpty) return;
                              Navigator.pop(context);
                              context.push('/document/$id');
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static String? _distanceLabel(Map<String, dynamic> item) {
    final dist = item['distanceMeters'];
    if (dist is! num) return null;
    if (dist < 1000) return '${dist.round()} m';
    return '${(dist / 1000).toStringAsFixed(1)} km';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(
            '$title ($count)',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
