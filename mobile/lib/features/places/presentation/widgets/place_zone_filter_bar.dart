import 'package:flutter/material.dart';

import '../../../../core/constants/place_zones.dart';

/// Lọc địa điểm theo khu vực campus.
class PlaceZoneFilterBar extends StatelessWidget {
  const PlaceZoneFilterBar({
    super.key,
    required this.selectedZone,
    required this.onChanged,
    required this.onApply,
  });

  final String? selectedZone;
  final ValueChanged<String?> onChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ZoneChip(
            label: 'Tất cả khu',
            selected: selectedZone == null,
            onTap: () {
              onChanged(null);
              onApply();
            },
            isDark: isDark,
            primary: theme.colorScheme.primary,
          ),
          ...PlaceZones.all.map(
            (zone) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _ZoneChip(
                label: zone.label,
                selected: selectedZone == zone.id,
                onTap: () {
                  onChanged(zone.id);
                  onApply();
                },
                isDark: isDark,
                primary: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.primary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected
            ? primary
            : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
      ),
      side: BorderSide(
        color: selected
            ? primary.withValues(alpha: 0.5)
            : (isDark ? Colors.white24 : const Color(0xFFE5E7EB)),
      ),
    );
  }
}
