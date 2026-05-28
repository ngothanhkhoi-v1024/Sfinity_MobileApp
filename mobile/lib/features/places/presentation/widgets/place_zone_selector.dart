import 'package:flutter/material.dart';

import '../../../../core/constants/place_zones.dart';

/// Chọn khu vực khi tạo/sửa địa điểm.
class PlaceZoneSelector extends StatelessWidget {
  const PlaceZoneSelector({
    super.key,
    required this.selectedZone,
    required this.onChanged,
  });

  final String? selectedZone;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khu vực',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Giúp lọc địa điểm theo khu trong trường',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          initialValue: selectedZone,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          hint: const Text('Chọn khu vực'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Chưa phân khu'),
            ),
            ...PlaceZones.all.map(
              (z) => DropdownMenuItem<String?>(
                value: z.id,
                child: Text(z.label),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
