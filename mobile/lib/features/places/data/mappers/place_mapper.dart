import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/constants/place_tags.dart';
import '../models/place_model.dart';

abstract final class PlaceMapper {
  static PlaceModel? fromJson(Map<String, dynamic> json) {
    final point = extractPoint(json);
    if (point == null) return null;

    final author = json['author'] as Map<String, dynamic>?;
    final dist = json['distanceMeters'];

    return PlaceModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Địa điểm',
      body: json['body']?.toString() ?? '',
      address: json['address']?.toString(),
      tags: PlaceTags.fromDynamicList(json['tags']).toList(),
      latitude: point.latitude,
      longitude: point.longitude,
      point: point,
      authorId: author?['id']?.toString() ?? json['authorId']?.toString(),
      authorName: author?['name']?.toString(),
      distanceMeters: dist is num ? dist.round() : null,
    );
  }

  static List<PlaceModel> listFromRaw(List<dynamic> raw) {
    final out = <PlaceModel>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final place = fromJson(entry);
      if (place != null) out.add(place);
    }
    return out;
  }

  static LatLng? extractPoint(Map<String, dynamic> data) {
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    if (latitude is num && longitude is num) {
      return MapConfig.latLngFromCoords(latitude.toDouble(), longitude.toDouble());
    }

    final body = data['body']?.toString() ?? '';
    if (body.contains('type:place')) {
      final latMatch = RegExp(r'lat:\s*([-\d.]+)').firstMatch(body);
      final lngMatch = RegExp(r'lng:\s*([-\d.]+)').firstMatch(body);
      if (latMatch != null && lngMatch != null) {
        final lat = double.tryParse(latMatch.group(1)!);
        final lng = double.tryParse(lngMatch.group(1)!);
        if (lat != null && lng != null) {
          return MapConfig.latLngFromCoords(lat, lng);
        }
      }
    }
    return null;
  }
}
