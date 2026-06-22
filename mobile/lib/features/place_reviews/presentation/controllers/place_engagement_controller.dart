import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../places/presentation/widgets/place_cover_image_picker.dart';

import '../../../../app.dart';
import '../../../../core/network/api_client.dart';
import '../../../places/data/services/place_location_service.dart';
import '../../../places/data/utils/place_checkin_geo.dart';
import '../../data/models/place_checkin_model.dart';
import '../../data/models/place_photo_model.dart';
import '../../data/models/place_review_model.dart';

class PlaceEngagementController extends ChangeNotifier {
  PlaceEngagementController({PlaceLocationService? location})
      : _location = location ?? PlaceLocationService();

  final PlaceLocationService _location;

  bool loading = true;
  bool submitting = false;
  bool checkInSubmitting = false;
  bool locatingNearby = false;
  String? error;

  PlaceReviewSummary? reviewSummary;
  PlacePhotoListResult? photoResult;
  PlaceCheckInStatus? checkInStatus;
  double? nearbyDistanceM;
  double? nearbyAccuracyM;
  bool? nearbyCanCheckIn;

  int draftRating = 5;
  final commentController = TextEditingController();

  void setDraftRating(int rating) {
    draftRating = rating;
    notifyListeners();
  }

  void _applyOwnReviewOrdering() {
    final summary = reviewSummary;
    if (summary == null || summary.reviews.isEmpty) return;

    final currentUserId = SfinityApp.auth.user?['id']?.toString();
    if (currentUserId == null) return;

    PlaceReviewModel? ownReview;
    final others = <PlaceReviewModel>[];
    for (final review in summary.reviews) {
      if (review.userId == currentUserId) {
        ownReview = review;
      } else {
        others.add(review);
      }
    }

    if (ownReview == null) return;

    draftRating = ownReview.rating;
    if (commentController.text.isEmpty) {
      commentController.text = ownReview.comment ?? '';
    }
    reviewSummary = PlaceReviewSummary(
      avgRating: summary.avgRating,
      reviewCount: summary.reviewCount,
      reviews: [ownReview, ...others],
    );
  }

  Future<void> load(String placeId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final reviewsFuture =
          SfinityApp.placeEngagementRepository.getReviews(placeId);
      final photosFuture =
          SfinityApp.placeEngagementRepository.getPhotos(placeId);
      final checkInFuture =
          SfinityApp.placeEngagementRepository.getCheckInStatus(placeId);
      final results =
          await Future.wait([reviewsFuture, photosFuture, checkInFuture]);
      reviewSummary = results[0] as PlaceReviewSummary;
      photoResult = results[1] as PlacePhotoListResult;
      checkInStatus = results[2] as PlaceCheckInStatus;
      _applyOwnReviewOrdering();
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> submitReview(String placeId) async {
    submitting = true;
    error = null;
    notifyListeners();

    try {
      final summary = await SfinityApp.placeEngagementRepository.submitReview(
        placeId,
        rating: draftRating,
        comment: commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
      );
      reviewSummary = PlaceReviewSummary(
        avgRating: summary.avgRating,
        reviewCount: summary.reviewCount,
        reviews: reviewSummary?.reviews ?? [],
      );
      await load(placeId);
      submitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
    } catch (e) {
      error = e.toString();
    }
    submitting = false;
    notifyListeners();
    return false;
  }

  Future<void> refreshNearby({
    required double placeLat,
    required double placeLng,
  }) async {
    locatingNearby = true;
    notifyListeners();

    final reading = await _location.getCurrentLocationReading();
    if (reading == null) {
      nearbyDistanceM = null;
      nearbyAccuracyM = null;
      nearbyCanCheckIn = false;
    } else {
      final dist = PlaceCheckInGeo.distanceM(
        userLat: reading.point.latitude,
        userLng: reading.point.longitude,
        placeLat: placeLat,
        placeLng: placeLng,
      );
      nearbyDistanceM = dist;
      nearbyAccuracyM = reading.accuracyM;
      nearbyCanCheckIn = PlaceCheckInGeo.isWithinRadius(
        distanceM: dist,
        accuracyM: reading.accuracyM,
      );
    }

    locatingNearby = false;
    notifyListeners();
  }

  Future<bool> submitCheckIn({
    required String placeId,
    required double placeLat,
    required double placeLng,
  }) async {
    if (checkInStatus?.hasCheckedIn == true) {
      return false;
    }

    checkInSubmitting = true;
    error = null;
    notifyListeners();

    try {
      final reading = await _location.getCurrentLocationReading();
      if (reading == null) {
        error = 'Không lấy được vị trí GPS. Bật định vị và thử lại.';
        checkInSubmitting = false;
        notifyListeners();
        return false;
      }

      final dist = PlaceCheckInGeo.distanceM(
        userLat: reading.point.latitude,
        userLng: reading.point.longitude,
        placeLat: placeLat,
        placeLng: placeLng,
      );
      nearbyDistanceM = dist;
      nearbyAccuracyM = reading.accuracyM;
      nearbyCanCheckIn = PlaceCheckInGeo.isWithinRadius(
        distanceM: dist,
        accuracyM: reading.accuracyM,
      );

      if (nearbyCanCheckIn != true) {
        final allowed = PlaceCheckInGeo.allowedRadiusM(reading.accuracyM);
        if (reading.accuracyM > PlaceCheckInGeo.maxAccuracyM) {
          error =
              'GPS không đủ chính xác (±${reading.accuracyM.round()} m). Di chuyển ra ngoài trời hoặc gần cửa sổ rồi thử lại.';
        } else {
          error =
              'Bạn cách địa điểm ${dist.round()} m (cho phép tối đa ${allowed.round()} m với GPS hiện tại).';
        }
        checkInSubmitting = false;
        notifyListeners();
        return false;
      }

      checkInStatus = await SfinityApp.placeEngagementRepository.submitCheckIn(
        placeId,
        latitude: reading.point.latitude,
        longitude: reading.point.longitude,
        accuracy: reading.accuracyM,
      );
      checkInSubmitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
    } catch (e) {
      error = e.toString();
    }
    checkInSubmitting = false;
    notifyListeners();
    return false;
  }

  Future<bool> pickAndUploadPhoto(String placeId) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1920,
      imageQuality: 85,
      limit: kMaxPlacePhotos,
    );
    if (picked.isEmpty) return false;

    submitting = true;
    error = null;
    notifyListeners();

    try {
      for (final item in picked) {
        await SfinityApp.placeEngagementRepository.uploadAndAddPhoto(
          placeId,
          imageFile: File(item.path),
        );
      }
      await load(placeId);
      submitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
    } catch (e) {
      error = e.toString();
    }
    submitting = false;
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
