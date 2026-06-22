import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app.dart';
import '../../../../core/network/api_client.dart';

class DocumentDetailController extends ChangeNotifier {
  bool downloading = false;
  String? error;
  Map<String, dynamic>? document;

  // Review & Rating state
  List<dynamic> reviews = [];
  double? avgRating;
  int reviewCount = 0;
  bool submittingReview = false;

  Future<void> load(String id) async {
    error = null;
    notifyListeners();

    try {
      document = await SfinityApp.documentRepository.getDocument(id);
      await loadReviews(id);
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
    } catch (e) {
      error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadReviews(String id) async {
    try {
      final res = await ApiClient.instance.get('/document/$id/reviews');
      avgRating = res['avgRating'] != null ? (res['avgRating'] as num).toDouble() : null;
      reviewCount = (res['reviewCount'] as num?)?.toInt() ?? 0;
      reviews = res['items'] as List? ?? [];
    } catch (_) {
      // Handle review loading error silently
    }
  }

  Future<bool> submitReview(String id, int rating, String comment) async {
    submittingReview = true;
    error = null;
    notifyListeners();

    try {
      await ApiClient.instance.post('/document/$id/reviews', {
        'rating': rating,
        'comment': comment.trim(),
      });
      await loadReviews(id);
      return true;
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
      return false;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      submittingReview = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReview(String id) async {
    submittingReview = true;
    error = null;
    notifyListeners();

    try {
      await ApiClient.instance.delete('/document/$id/reviews');
      await loadReviews(id);
      return true;
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
      return false;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      submittingReview = false;
      notifyListeners();
    }
  }

  Future<bool> triggerDownload(String fileUrl, {void Function(String message)? onLimitReached}) async {
    if (document == null) return false;

    final limits = SfinityApp.userLimits;
    if (!limits.canDownloadDocument) {
      error = 'limit';
      notifyListeners();
      onLimitReached?.call('downloads');
      return false;
    }

    downloading = true;
    error = null;
    notifyListeners();

    try {
      await ApiClient.instance.patch('/document/${document!['id']}/download', {});
      if (document!['downloadsCount'] != null) {
        document!['downloadsCount'] = (document!['downloadsCount'] as int) + 1;
      }
      await SfinityApp.userLimits.refresh();
      
      final uri = Uri.parse(fileUrl);
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (launched) {
        return true;
      } else {
        error = 'Không thể mở liên kết tải xuống tài liệu';
        return false;
      }
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
      if (e.response?.statusCode == 403) {
        await SfinityApp.userLimits.refresh();
        onLimitReached?.call('downloads');
      }
      return false;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      downloading = false;
      notifyListeners();
    }
  }
}
