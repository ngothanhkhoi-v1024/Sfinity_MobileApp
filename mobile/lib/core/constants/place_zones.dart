/// Khu vực campus — đồng bộ với backend `place-zones.ts`.
class PlaceZone {
  const PlaceZone({required this.id, required this.label});

  final String id;
  final String label;
}

abstract final class PlaceZones {
  static const all = [
    PlaceZone(id: 'khu_a', label: 'Khu A'),
    PlaceZone(id: 'khu_b', label: 'Khu B'),
    PlaceZone(id: 'library', label: 'Thư viện'),
    PlaceZone(id: 'dorm', label: 'Ký túc xá'),
    PlaceZone(id: 'cafeteria', label: 'Căng tin'),
    PlaceZone(id: 'sports', label: 'Sân thể thao'),
    PlaceZone(id: 'faculty_it', label: 'Khoa CNTT'),
    PlaceZone(id: 'faculty_biz', label: 'Khoa Kinh tế'),
    PlaceZone(id: 'other', label: 'Khác'),
  ];

  static PlaceZone? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final z in all) {
      if (z.id == id) return z;
    }
    return null;
  }

  static String labelFor(String? id) => byId(id)?.label ?? 'Chưa phân khu';
}
