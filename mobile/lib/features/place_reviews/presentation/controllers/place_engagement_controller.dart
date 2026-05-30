import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/place_photo_model.dart';
import '../../data/models/place_review_model.dart';

class PlaceEngagementController extends ChangeNotifier {
  bool loading = true;
  bool submitting = false;
  String? error;

  PlaceReviewSummary? reviewSummary;
  PlacePhotoListResult? photoResult;

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
      final results = await Future.wait([reviewsFuture, photosFuture]);
      reviewSummary = results[0] as PlaceReviewSummary;
      photoResult = results[1] as PlacePhotoListResult;
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
    if (!SfinityApp.auth.isAuthenticated) {
      error = 'Đăng nhập để đánh giá địa điểm';
      notifyListeners();
      return false;
    }

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

  Future<bool> pickAndUploadPhoto(String placeId) async {
    if (!SfinityApp.auth.isAuthenticated) {
      error = 'Đăng nhập để thêm ảnh';
      notifyListeners();
      return false;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked == null) return false;

    submitting = true;
    error = null;
    notifyListeners();

    try {
      await SfinityApp.placeEngagementRepository.uploadAndAddPhoto(
        placeId,
        imageFile: File(picked.path),
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

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
