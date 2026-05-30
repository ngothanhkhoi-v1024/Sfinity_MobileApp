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
        'comment': comment.trim(), // Send empty string if it's cleared/empty
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

  Future<bool> triggerDownload(String fileUrl) async {
    if (document == null) return false;
    downloading = true;
    error = null;
    notifyListeners();

    try {
      // 1. Increment download count in backend
      await ApiClient.instance.patch('/document/${document!['id']}/download', {});
      
      // Update local downloadsCount representation
      if (document!['downloadsCount'] != null) {
        document!['downloadsCount'] = (document!['downloadsCount'] as int) + 1;
      }

      // 2. Launch the file URL in browser
      final uri = Uri.parse(fileUrl);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      } else {
        error = 'Không thể mở liên kết tải xuống tài liệu';
        return false;
      }
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
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
