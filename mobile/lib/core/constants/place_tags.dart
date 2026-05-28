import 'package:flutter/material.dart';

/// Tag tiện ích học tập cho địa điểm — đồng bộ với backend `PLACE_STUDY_TAGS`.
class PlaceStudyTag {
  const PlaceStudyTag({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

abstract final class PlaceTags {
  static const all = <PlaceStudyTag>[
    PlaceStudyTag(id: 'wifi', label: 'WiFi', icon: Icons.wifi),
    PlaceStudyTag(id: 'outlet', label: 'Ổ cắm', icon: Icons.power_outlined),
    PlaceStudyTag(id: 'quiet', label: 'Yên tĩnh', icon: Icons.volume_off_outlined),
    PlaceStudyTag(id: 'open_late', label: 'Mở muộn', icon: Icons.schedule_outlined),
    PlaceStudyTag(id: 'ac', label: 'Điều hòa', icon: Icons.ac_unit_outlined),
    PlaceStudyTag(id: 'parking', label: 'Giữ xe', icon: Icons.local_parking_outlined),
  ];

  static PlaceStudyTag? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static String labelsFor(List<String> ids) {
    return ids
        .map((id) => byId(id)?.label ?? id)
        .where((l) => l.isNotEmpty)
        .join(' · ');
  }

  static String toQueryParam(Set<String> selected) {
    if (selected.isEmpty) return '';
    return selected.join(',');
  }

  static Set<String> fromDynamicList(dynamic raw) {
    if (raw is! List) return {};
    return raw.map((e) => e.toString()).toSet();
  }
}
