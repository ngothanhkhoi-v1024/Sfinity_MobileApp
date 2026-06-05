import 'package:latlong2/latlong.dart';

/// Địa điểm học tập (`type=place` trên API document).
class PlaceModel {
  const PlaceModel({
    required this.id,
    required this.title,
    required this.body,
    this.address,
    this.zone,
    this.tags = const [],
    this.latitude,
    this.longitude,
    this.point,
    this.authorId,
    this.authorName,
    this.distanceMeters,
    this.avgRating,
    this.reviewCount,
    this.status,
  });

  final String id;
  final String title;
  final String body;
  final String? address;
  final String? zone;
  final List<String> tags;
  final double? latitude;
  final double? longitude;
  final LatLng? point;
  final String? authorId;
  final String? authorName;
  final int? distanceMeters;
  final double? avgRating;
  final int? reviewCount;
  final String? status;

  bool get hasPoint => point != null;
  bool get isPublic => status == null || status == 'PUBLISHED';
}

/// Tham số liệt kê địa điểm.
class PlaceListQuery {
  const PlaceListQuery({
    this.search,
    this.tags = const {},
    this.lat,
    this.lng,
    this.radiusKm,
    this.zone,
    this.authorId,
    this.publishedOnly = false,
    this.limit = 50,
  });

  final String? search;
  final Set<String> tags;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final String? zone;
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
    this.zone,
    this.tags = const [],
    this.isPublic = true,
  });

  final String title;
  final String body;
  final double latitude;
  final double longitude;
  final String address;
  final String? zone;
  final List<String> tags;
  final bool isPublic;

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        if (zone != null && zone!.isNotEmpty) 'zone': zone,
        'tags': tags,
        'status': isPublic ? 'PUBLISHED' : 'DRAFT',
      };
}
