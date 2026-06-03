import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../models/place_checkin_model.dart';
import '../models/place_photo_model.dart';
import '../models/place_review_model.dart';
import '../services/place_engagement_api_service.dart';
import 'place_engagement_repository.dart';

class PlaceEngagementRepositoryImpl implements PlaceEngagementRepository {
  PlaceEngagementRepositoryImpl(this._api);

  final PlaceEngagementApiService _api;

  @override
  Future<PlaceReviewSummary> getReviews(String placeId) async {
    final res = await _api.getReviews(placeId);
    return PlaceReviewSummary.fromJson(Map<String, dynamic>.from(res));
  }

  @override
  Future<PlaceReviewSummary> submitReview(
    String placeId, {
    required int rating,
    String? comment,
  }) async {
    final res = await _api.submitReview(placeId, rating: rating, comment: comment);
    return PlaceReviewSummary(
      avgRating: (res['avgRating'] as num?)?.toDouble(),
      reviewCount: (res['reviewCount'] as num?)?.toInt() ?? 0,
      reviews: [],
    );
  }

  @override
  Future<PlacePhotoListResult> getPhotos(String placeId) async {
    final res = await _api.getPhotos(placeId);
    return PlacePhotoListResult.fromJson(Map<String, dynamic>.from(res));
  }

  @override
  Future<PlacePhotoModel> uploadAndAddPhoto(
    String placeId, {
    required File imageFile,
    String? caption,
    void Function(double progress)? onProgress,
  }) async {
    final remoteName =
        '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split(RegExp(r'[/\\]')).last}';
    final path = 'place_photos/$placeId/$remoteName';

    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = ref.putFile(imageFile);

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
    }

    final snapshot = await uploadTask;
    final imageUrl = await snapshot.ref.getDownloadURL();

    final res = await _api.addPhoto(placeId, imageUrl: imageUrl, caption: caption);
    return PlacePhotoModel.fromJson(Map<String, dynamic>.from(res));
  }

  @override
  Future<void> deletePhoto(String placeId, String photoId) {
    return _api.deletePhoto(placeId, photoId);
  }

  @override
  Future<PlaceCheckInStatus> getCheckInStatus(String placeId) async {
    final res = await _api.getCheckInStatus(placeId);
    return PlaceCheckInStatus.fromJson(Map<String, dynamic>.from(res));
  }

  @override
  Future<PlaceCheckInStatus> submitCheckIn(
    String placeId, {
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    final res = await _api.submitCheckIn(
      placeId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
    return PlaceCheckInStatus.fromJson(Map<String, dynamic>.from(res));
  }
}
