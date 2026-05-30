import '../../../../features/document/data/services/document_api_service.dart';

/// API địa điểm — bọc document API với `type=place`.
class PlaceApiService {
  PlaceApiService(this._documents);

  final DocumentApiService _documents;

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
  }) {
    return _documents.getDocuments(
      type: 'place',
      search: search,
      tags: tags,
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      zone: zone,
      authorId: authorId,
      publishedOnly: publishedOnly,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> getPlace(String id) {
    return _documents.getDocument(id);
  }

  Future<Map<String, dynamic>> createPlace(Map<String, dynamic> payload) {
    return _documents.createDocument(payload);
  }

  Future<Map<String, dynamic>> updatePlace(String id, Map<String, dynamic> payload) {
    return _documents.updateDocument(id, payload);
  }

  Future<void> deletePlace(String id) {
    return _documents.deleteDocument(id);
  }

  Future<Map<String, dynamic>> listDocumentsAtPlace(String placeId) {
    return _documents.getDocuments(
      type: 'document',
      placeId: placeId,
      publishedOnly: true,
      limit: 50,
    );
  }
}
