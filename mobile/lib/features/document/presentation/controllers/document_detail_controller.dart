import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app.dart';
import '../../../../core/network/api_client.dart';

class DocumentDetailController extends ChangeNotifier {
  bool downloading = false;
  String? error;
  Map<String, dynamic>? document;

  Future<void> load(String id) async {
    error = null;
    notifyListeners();

    try {
      document = await SfinityApp.documentRepository.getDocument(id);
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
    } catch (e) {
      error = e.toString();
    } finally {
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
        error = 'Không thể mở liên kết tài liệu này';
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
