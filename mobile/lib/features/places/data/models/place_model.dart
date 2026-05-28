import 'package:latlong2/latlong.dart';

/// Địa điểm học tập (`type=place` trên API document).
class PlaceModel {
  const PlaceModel({
    required this.id,
    required this.title,
    required this.body,
    this.address,
    this.tags = const [],
    this.latitude,
    this.longitude,
    this.point,
    this.authorId,
    this.authorName,
    this.distanceMeters,
  });

  final String id;
  final String title;
  final String body;
  final String? address;
  final List<String> tags;
  final double? latitude;
  final double? longitude;
  final LatLng? point;
  final String? authorId;
  final String? authorName;
  final int? distanceMeters;

  bool get hasPoint => point != null;
}

/// Tham số liệt kê địa điểm.
class PlaceListQuery {
  const PlaceListQuery({
    this.search,
    this.tags = const {},
    this.lat,
    this.lng,
    this.radiusKm,
    this.authorId,
    this.publishedOnly = false,
    this.limit = 50,
  });

  final String? search;
  final Set<String> tags;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final String? authorId;
  final bool publishedOnly;
  final int limit;
}

/// Payload tạo/cập nhật địa điểm.
class PlaceUpsertPayload {
  const PlaceUpsertPayload({
    required this.title,
    required this.body,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.tags = const [],
  });

  final String title;
  final String body;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> tags;

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'type': 'place',
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'tags': tags,
        'status': 'PUBLISHED',
      };
}
