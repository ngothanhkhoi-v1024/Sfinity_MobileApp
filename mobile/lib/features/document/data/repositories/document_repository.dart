abstract class DocumentRepository {
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
  });

  Future<Map<String, dynamic>> getDocument(String id);

  Future<Map<String, dynamic>> createDocument(Map<String, dynamic> payload);

  Future<Map<String, dynamic>> updateDocument(String id, Map<String, dynamic> payload);

  Future<void> deleteDocument(String id);

  Future<List<dynamic>> getCategories();
}
