import '../services/document_api_service.dart';
import 'document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl(this._apiService);

  final DocumentApiService _apiService;

  @override
  Future<Map<String, dynamic>> getDocuments({
    String? categoryId,
    String? search,
    bool? publishedOnly,
    int? limit,
  }) {
    return _apiService.getDocuments(
      categoryId: categoryId,
      search: search,
      publishedOnly: publishedOnly,
      limit: limit,
    );
  }

  @override
  Future<Map<String, dynamic>> getDocument(String id) {
    return _apiService.getDocument(id);
  }

  @override
  Future<Map<String, dynamic>> createDocument(Map<String, dynamic> payload) {
    return _apiService.createDocument(payload);
  }

  @override
  Future<Map<String, dynamic>> updateDocument(String id, Map<String, dynamic> payload) {
    return _apiService.updateDocument(id, payload);
  }

  @override
  Future<void> deleteDocument(String id) {
    return _apiService.deleteDocument(id);
  }

  @override
  Future<List<dynamic>> getCategories() {
    return _apiService.getCategories();
  }
}
