/// Kết quả API `GET /study-near-me`.
class StudyNearMeResult {
  const StudyNearMeResult({
    required this.radiusKm,
    required this.places,
    required this.documents,
    required this.placeCount,
    required this.documentCount,
    this.lat,
    this.lng,
  });

  final double radiusKm;
  final double? lat;
  final double? lng;
  final List<Map<String, dynamic>> places;
  final List<Map<String, dynamic>> documents;
  final int placeCount;
  final int documentCount;

  factory StudyNearMeResult.fromJson(Map<String, dynamic> json) {
    final center = json['center'] as Map<String, dynamic>?;
    return StudyNearMeResult(
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 3,
      lat: (center?['lat'] as num?)?.toDouble(),
      lng: (center?['lng'] as num?)?.toDouble(),
      places: (json['places'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          [],
      documents: (json['documents'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          [],
      placeCount: (json['placeCount'] as num?)?.toInt() ?? 0,
      documentCount: (json['documentCount'] as num?)?.toInt() ?? 0,
    );
  }

  int get totalCount => places.length + documents.length;
}
