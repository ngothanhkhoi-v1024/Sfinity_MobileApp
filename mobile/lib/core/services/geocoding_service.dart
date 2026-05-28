import 'package:dio/dio.dart';

/// Reverse/forward geocoding via OpenStreetMap Nominatim (no API key).
class GeocodingService {
  GeocodingService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: const {
                  'User-Agent': 'SfinityMobile/1.0 (educational map app)',
                },
              ),
            );

  final Dio _dio;

  static const _base = 'https://nominatim.openstreetmap.org';

  Future<String?> reverseAddress(double lat, double lng) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$_base/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'addressdetails': '1',
        },
      );
      final data = res.data;
      if (data == null) return null;
      final display = data['display_name']?.toString();
      if (display != null && display.isNotEmpty) return display;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<GeocodingResult>> search(String query, {int limit = 5}) async {
    final q = query.trim();
    if (q.length < 2) return [];
    try {
      final res = await _dio.get<List<dynamic>>(
        '$_base/search',
        queryParameters: {
          'q': q,
          'format': 'json',
          'limit': limit,
        },
      );
      final list = res.data ?? [];
      return list
          .whereType<Map>()
          .map((e) => GeocodingResult.fromJson(Map<String, dynamic>.from(e)))
          .where((r) => r.lat != null && r.lng != null)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class GeocodingResult {
  GeocodingResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  final String displayName;
  final double? lat;
  final double? lng;

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      displayName: json['display_name']?.toString() ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? ''),
      lng: double.tryParse(json['lon']?.toString() ?? ''),
    );
  }
}
