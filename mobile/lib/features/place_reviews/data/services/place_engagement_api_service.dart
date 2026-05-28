import '../../../../core/network/api_client.dart';

class PlaceEngagementApiService {
  PlaceEngagementApiService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getReviews(String placeId) {
    return _api.get('/places/$placeId/reviews');
  }

  Future<Map<String, dynamic>> submitReview(
    String placeId, {
    required int rating,
    String? comment,
  }) {
    return _api.post('/places/$placeId/reviews', {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  Future<Map<String, dynamic>> getPhotos(String placeId) {
    return _api.get('/places/$placeId/photos');
  }

  Future<Map<String, dynamic>> addPhoto(
    String placeId, {
    required String imageUrl,
    String? caption,
  }) {
    return _api.post('/places/$placeId/photos', {
      'imageUrl': imageUrl,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });
  }

  Future<void> deletePhoto(String placeId, String photoId) {
    return _api.delete('/places/$placeId/photos/$photoId');
  }
}
