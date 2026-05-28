import '../../../../core/network/api_client.dart';

class DocumentApiService {
  DocumentApiService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getDocuments({
    String? categoryId,
    String? search,
    String? type,
    String? authorId,
    String? placeId,
    String? tags,
    double? lat,
    double? lng,
    double? radiusKm,
    bool? publishedOnly,
    int? limit,
  }) {
    return _api.get('/document', query: {
      if (categoryId != null) 'categoryId': categoryId,
      if (search != null) 'search': search,
      if (type != null) 'type': type,
      if (authorId != null) 'authorId': authorId,
      if (placeId != null) 'placeId': placeId,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      if (radiusKm != null) 'radiusKm': radiusKm.toString(),
      if (publishedOnly != null) 'publishedOnly': publishedOnly.toString(),
      if (limit != null) 'limit': limit.toString(),
    });
  }

  Future<Map<String, dynamic>> getDocument(String id) {
    return _api.get('/document/$id');
  }

  Future<Map<String, dynamic>> createDocument(Map<String, dynamic> payload) {
    return _api.post('/document', payload);
  }

  Future<Map<String, dynamic>> updateDocument(String id, Map<String, dynamic> payload) {
    return _api.patch('/document/$id', payload);
  }

  Future<void> deleteDocument(String id) {
    return _api.delete('/document/$id');
  }

  Future<List<dynamic>> getCategories() {
    return _api.getList('/categories');
  }
}
