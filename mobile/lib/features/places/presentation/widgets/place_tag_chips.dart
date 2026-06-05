import 'package:flutter/material.dart';

import '../../../../core/constants/place_tags.dart';
import '../../../../core/i18n/app_text.dart';

class PlaceTagSelector extends StatelessWidget {
  const PlaceTagSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  void _toggle(String id) {
    final next = Set<String>.from(selected);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.filterAmenities,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.placeDescriptionDetail,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in PlaceTags.all)
              FilterChip(
                label: Text(tag.label),
                avatar: Icon(tag.icon, size: 18),
                selected: selected.contains(tag.id),
                onSelected: (_) => _toggle(tag.id),
                showCheckmark: true,
              ),
          ],
        ),
      ],
    );
  }
}

class PlaceTagDisplay extends StatelessWidget {
  const PlaceTagDisplay({super.key, required this.tagIds});

  final List<String> tagIds;

  @override
  Widget build(BuildContext context) {
    if (tagIds.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final isDark = theme.brightness == Brightness.dark;
    final pillBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final id in tagIds)
          if (PlaceTags.byId(id) != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PlaceTags.byId(id)!.icon, size: 16, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    PlaceTags.byId(id)!.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade200 : const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class PlaceTagFilterBar extends StatelessWidget {
  const PlaceTagFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.onApply,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final VoidCallback? onApply;

  void _toggle(String id) {
    final next = Set<String>.from(selected);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    onChanged(next);
    onApply?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          if (selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(l10n.removeFilter),
                avatar: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  onChanged({});
                  onApply?.call();
                },
              ),
            ),
          for (final tag in PlaceTags.all)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(tag.label, style: const TextStyle(fontSize: 12)),
                avatar: Icon(tag.icon, size: 16),
                selected: selected.contains(tag.id),
                onSelected: (_) => _toggle(tag.id),
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.15),
              ),
            ),
        ],
      ),
    );
  }
}
