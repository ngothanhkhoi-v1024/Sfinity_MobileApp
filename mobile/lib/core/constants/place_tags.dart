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
  static List<PlaceStudyTag> _all = [
    const PlaceStudyTag(id: 'wifi', label: 'WiFi', icon: Icons.wifi),
    const PlaceStudyTag(id: 'outlet', label: 'Ổ cắm', icon: Icons.power_outlined),
    const PlaceStudyTag(id: 'quiet', label: 'Yên tĩnh', icon: Icons.volume_off_outlined),
    const PlaceStudyTag(id: 'open_late', label: 'Mở muộn', icon: Icons.schedule_outlined),
    const PlaceStudyTag(id: 'ac', label: 'Điều hòa', icon: Icons.ac_unit_outlined),
    const PlaceStudyTag(id: 'parking', label: 'Giữ xe', icon: Icons.local_parking_outlined),
  ];

  static List<PlaceStudyTag> get all => _all;

  static void initialize(List<dynamic> apiData) {
    final list = <PlaceStudyTag>[];
    for (final entry in apiData) {
      if (entry is! Map) continue;
      final id = entry['id']?.toString() ?? '';
      final name = entry['name']?.toString() ?? '';
      if (id.isEmpty || name.isEmpty) continue;
      list.add(PlaceStudyTag(
        id: id,
        label: name,
        icon: _getIconForIdOrName(id, name),
      ));
    }
    if (list.isNotEmpty) {
      _all = list;
    }
  }

  static IconData _getIconForIdOrName(String id, String name) {
    switch (id) {
      case 'wifi':
        return Icons.wifi;
      case 'outlet':
        return Icons.power_outlined;
      case 'quiet':
        return Icons.volume_off_outlined;
      case 'open_late':
        return Icons.schedule_outlined;
      case 'ac':
        return Icons.ac_unit_outlined;
      case 'parking':
        return Icons.local_parking_outlined;
    }

    final lower = name.toLowerCase();
    if (lower.contains('wifi')) {
      return Icons.wifi;
    }
    if (lower.contains('ổ cắm') || lower.contains('o cam') || lower.contains('outlet')) {
      return Icons.power_outlined;
    }
    if (lower.contains('yên tĩnh') || lower.contains('yen tinh') || lower.contains('quiet')) {
      return Icons.volume_off_outlined;
    }
    if (lower.contains('muộn') || lower.contains('muon') || lower.contains('late') || lower.contains('24h')) {
      return Icons.schedule_outlined;
    }
    if (lower.contains('điều hòa') || lower.contains('dieu hoa') || lower.contains('máy lạnh') || lower.contains('ac')) {
      return Icons.ac_unit_outlined;
    }
    if (lower.contains('giữ xe') || lower.contains('giu xe') || lower.contains('bãi xe') || lower.contains('parking')) {
      return Icons.local_parking_outlined;
    }

    return Icons.label_outline;
  }

  static PlaceStudyTag? byId(String id) {
    for (final t in _all) {
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
