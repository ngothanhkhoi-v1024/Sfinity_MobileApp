import '../../../../core/network/api_client.dart';

/// API địa điểm.
class PlaceApiService {
  PlaceApiService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> listPlaces({
    String? search,
    String? tags,
    double? lat,
    double? lng,
    double? radiusKm,
    String? zone,
    String? authorId,
    bool publishedOnly = false,
    int limit = 50,
    int? minRating,
  }) {
    return _api.get('/places', query: {
      if (search != null) 'search': search,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      if (radiusKm != null) 'radiusKm': radiusKm.toString(),
      if (zone != null && zone.isNotEmpty) 'zone': zone,
      if (authorId != null) 'authorId': authorId,
      if (minRating != null && minRating > 0) 'minRating': minRating.toString(),
      'publishedOnly': publishedOnly.toString(),
      'limit': limit.toString(),
    });
  }

  Future<Map<String, dynamic>> getPlace(String id) {
    return _api.get('/places/$id');
  }

  Future<Map<String, dynamic>> getPlaceWeather(String id) {
    return _api.get('/places/$id/weather');
  }

  Future<Map<String, dynamic>> createPlace(Map<String, dynamic> payload) {
    return _api.post('/places', payload);
  }

  Future<Map<String, dynamic>> updatePlace(String id, Map<String, dynamic> payload) {
    return _api.patch('/places/$id', payload);
  }

  Future<void> deletePlace(String id) {
    return _api.delete('/places/$id');
  }

  Future<Map<String, dynamic>> listDocumentsAtPlace(String placeId) {
    return _api.get('/document', query: {
      'placeId': placeId,
      'publishedOnly': 'true',
      'limit': '50',
    });
  }
}
