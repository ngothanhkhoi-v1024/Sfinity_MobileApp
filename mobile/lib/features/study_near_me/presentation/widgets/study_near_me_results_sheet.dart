import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/study_near_me_result.dart';
import '../controllers/study_near_me_controller.dart';

class StudyNearMeResultsSheet extends StatefulWidget {
  const StudyNearMeResultsSheet({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.scrollController,
    required this.sheetController,
  });

  final StudyNearMeController controller;
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;

  static const _compactSize = 0.42;
  static const _expandedSize = 0.78;

  static Future<void> show(
    BuildContext context, {
    required StudyNearMeController controller,
    required Future<void> Function() onRefresh,
  }) {
    final sheetController = DraggableScrollableController();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        controller: sheetController,
        expand: false,
        initialChildSize: _compactSize,
        minChildSize: 0.28,
        maxChildSize: 0.88,
        builder: (_, scrollController) => StudyNearMeResultsSheet(
          controller: controller,
          onRefresh: onRefresh,
          scrollController: scrollController,
          sheetController: sheetController,
        ),
      ),
    );
  }

  @override
  State<StudyNearMeResultsSheet> createState() => _StudyNearMeResultsSheetState();
}

class _StudyNearMeResultsSheetState extends State<StudyNearMeResultsSheet> {
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.loading && _showAll) {
      setState(() => _showAll = false);
      _animateSheet(compact: true);
    }
  }

  Future<void> _animateSheet({required bool compact}) async {
    if (!widget.sheetController.isAttached) return;
    await widget.sheetController.animateTo(
      compact ? StudyNearMeResultsSheet._compactSize : StudyNearMeResultsSheet._expandedSize,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _expandAll() {
    setState(() => _showAll = true);
    _animateSheet(compact: false);
  }

  void _collapse() {
    setState(() => _showAll = false);
    _animateSheet(compact: true);
    if (widget.scrollController.hasClients) {
      widget.scrollController.jumpTo(0);
    }
  }

  void _openItem(BuildContext context, _NearestEntry entry) {
    final id = entry.item['id']?.toString();
    if (id == null || id.isEmpty) return;
    Navigator.pop(context);
    if (entry.type == _NearestType.place) {
      context.push('/places/$id');
    } else {
      context.push('/document/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final result = widget.controller.result;
        final loading = widget.controller.loading;
        final error = widget.controller.error;

        if (result == null && !loading) {
          return const SizedBox.shrink();
        }

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
              _Header(
                result: result,
                loading: loading,
                onRefresh: loading ? null : widget.onRefresh,
              ),
              const Divider(height: 1),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                        ? _ErrorBody(message: error, onRetry: widget.onRefresh)
                        : result == null || result.totalCount == 0
                            ? _EmptyBody()
                            : _showAll
                                ? _AllResultsBody(
                                    result: result,
                                    scrollController: widget.scrollController,
                                    onItemTap: (entry) => _openItem(context, entry),
                                    onCollapse: _collapse,
                                  )
                                : _NearestBody(
                                    result: result,
                                    scrollController: widget.scrollController,
                                    onItemTap: (entry) => _openItem(context, entry),
                                    onViewAll: _expandAll,
                                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.result,
    required this.loading,
    required this.onRefresh,
  });

  final StudyNearMeResult? result;
  final bool loading;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final summary = result == null
        ? l10n.loading
        : '${result!.placeCount} ${l10n.places} · ${result!.documentCount} ${l10n.documents} · ${result!.radiusKm.toStringAsFixed(0)} km';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.studyNearMe,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh == null ? null : () => onRefresh!(),
            icon: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: l10n.findAgain,
          ),
        ],
      ),
    );
  }
}

class _NearestBody extends StatelessWidget {
  const _NearestBody({
    required this.result,
    required this.scrollController,
    required this.onItemTap,
    required this.onViewAll,
  });

  final StudyNearMeResult result;
  final ScrollController scrollController;
  final ValueChanged<_NearestEntry> onItemTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = _sortedEntries(result);
    if (entries.isEmpty) return _EmptyBody();
    final nearest = entries.first;

    final isPlace = nearest.type == _NearestType.place;
    final title = nearest.item['title']?.toString() ??
        (isPlace ? l10n.places : l10n.documents);
    final others = result.totalCount - 1;
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        Text(
          l10n.studyNearMeNearest,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted(context),
          ),
        ),
        const SizedBox(height: 8),
        _ResultTile(
          icon: isPlace ? Icons.place_rounded : Icons.description_outlined,
          title: title,
          subtitle: _distanceLabel(nearest.item),
          onTap: () => onItemTap(nearest),
        ),
        if (others > 0) ...[
          const SizedBox(height: 10),
          Text(
            l10n.studyNearMeMoreInRadius(others),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewAll,
              icon: Icon(Icons.unfold_more_rounded, size: 18, color: primary),
              label: Text(l10n.studyNearMeViewAll(result.totalCount)),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.35)),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AllResultsBody extends StatelessWidget {
  const _AllResultsBody({
    required this.result,
    required this.scrollController,
    required this.onItemTap,
    required this.onCollapse,
  });

  final StudyNearMeResult result;
  final ScrollController scrollController;
  final ValueChanged<_NearestEntry> onItemTap;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = _sortedEntries(result);
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.studyNearMeViewAll(result.totalCount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted(context),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onCollapse,
                icon: Icon(Icons.unfold_less_rounded, size: 18, color: primary),
                label: Text(l10n.studyNearMeShowLess),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: entries.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isPlace = entry.type == _NearestType.place;
              final title = entry.item['title']?.toString() ??
                  (isPlace ? l10n.places : l10n.documents);
              return _ResultTile(
                icon: isPlace ? Icons.place_rounded : Icons.description_outlined,
                title: title,
                subtitle: _distanceLabel(entry.item),
                onTap: () => onItemTap(entry),
              );
            },
          ),
        ),
      ],
    );
  }
}

enum _NearestType { place, document }

class _NearestEntry {
  const _NearestEntry({required this.type, required this.item});

  final _NearestType type;
  final Map<String, dynamic> item;
}

List<_NearestEntry> _sortedEntries(StudyNearMeResult result) {
  final candidates = <_NearestEntry>[
    for (final p in result.places) _NearestEntry(type: _NearestType.place, item: p),
    for (final d in result.documents) _NearestEntry(type: _NearestType.document, item: d),
  ];
  candidates.sort((a, b) {
    final da = (a.item['distanceMeters'] as num?)?.toDouble() ?? double.infinity;
    final db = (b.item['distanceMeters'] as num?)?.toDouble() ?? double.infinity;
    return da.compareTo(db);
  });
  return candidates;
}

String? _distanceLabel(Map<String, dynamic> item) {
  final dist = item['distanceMeters'];
  if (dist is! num) return null;
  if (dist < 1000) return '${dist.round()} m';
  return '${(dist / 1000).toStringAsFixed(1)} km';
}

class _EmptyBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(l10n.noPlaceFoundInArea, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: Colors.grey.shade500),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.findAgain),
            ),
          ],
        ),
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
    final primary = theme.colorScheme.primary;

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border(context)),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: AppColors.muted(context)),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted(context)),
            ],
          ),
        ),
      ),
    );
  }
}
