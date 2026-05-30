import '../../../../core/network/api_client.dart';

class StudyNearMeApiService {
  StudyNearMeApiService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> findNearby({
    required double lat,
    required double lng,
    double? radiusKm,
    int? limit,
  }) {
    return _api.get('/study-near-me', query: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      if (radiusKm != null) 'radiusKm': radiusKm.toString(),
      if (limit != null) 'limit': limit.toString(),
    });
  }
}
