import 'dart:io';

import '../models/place_checkin_model.dart';
import '../models/place_photo_model.dart';
import '../models/place_review_model.dart';

abstract class PlaceEngagementRepository {
  Future<PlaceReviewSummary> getReviews(String placeId);

  Future<PlaceReviewSummary> submitReview(
    String placeId, {
    required int rating,
    String? comment,
  });

  Future<PlacePhotoListResult> getPhotos(String placeId);

  Future<PlacePhotoModel> uploadAndAddPhoto(
    String placeId, {
    required File imageFile,
    String? caption,
    void Function(double progress)? onProgress,
  });

  Future<void> deletePhoto(String placeId, String photoId);

  Future<PlaceCheckInStatus> getCheckInStatus(String placeId);

  Future<PlaceCheckInStatus> submitCheckIn(
    String placeId, {
    required double latitude,
    required double longitude,
    required double accuracy,
  });
}
