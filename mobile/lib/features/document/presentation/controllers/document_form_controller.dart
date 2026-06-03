import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../../../../core/network/api_client.dart';

class DocumentFormController extends ChangeNotifier {
  bool loading = false;
  List<dynamic> categories = [];
  String? selectedCategoryId;

  // File Upload State
  bool useUpload = true;
  String? uploadedFileUrl;
  String? uploadedFileName;
  String? uploadedFileType;
  int? uploadedFileSize;
  double uploadProgress = 0.0;
  bool uploading = false;
  File? localFileToUpload;
  String selectedStatus = 'PENDING';

  void selectStatus(String? val) {
    final isAdmin = SfinityApp.auth.user?['role']?.toString() == 'admin';
    if (!isAdmin) {
      selectedStatus = (val == 'DRAFT') ? 'DRAFT' : 'PENDING';
    } else {
      selectedStatus = val ?? 'PUBLISHED';
    }
    notifyListeners();
  }

  Future<void> loadCategories(String? initialCategoryId, bool isEdit) async {
    try {
      categories = await SfinityApp.documentRepository.getCategories();
      if (categories.isNotEmpty && selectedCategoryId == null && !isEdit) {
        selectedCategoryId = categories.first['id']?.toString();
      }
      notifyListeners();
    } catch (_) {}
  }

  void setUseUpload(bool val) {
    useUpload = val;
    notifyListeners();
  }

  void selectCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      const int maxSizeBytes = 200 * 1024 * 1024;
      if (file.size > maxSizeBytes) {
        throw 'Kích thước tệp vượt quá giới hạn cho phép (tối đa 200MB).';
      }

      localFileToUpload = File(file.path!);
      uploadedFileName = file.name;
      uploadedFileType = 'pdf';
      uploadedFileSize = file.size;
      uploadedFileUrl = null;
      uploadProgress = 0.0;
      notifyListeners();
    } catch (e) {
      throw 'Chọn tệp thất bại: $e';
    }
  }

  Future<String> _uploadToStorage(File localFile, String remoteName) async {
    final path = 'documents/$remoteName';
    final buckets = [
      null,
      'mobile-e1ac5.appspot.com',
    ];

    dynamic lastError;

    for (final bucket in buckets) {
      try {
        final storage = bucket == null
            ? FirebaseStorage.instance
            : FirebaseStorage.instanceFor(bucket: bucket);

        final ref = storage.ref().child(path);
        final uploadTask = ref.putFile(localFile);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          notifyListeners();
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        lastError = e;
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('object-not-found')) {
          continue;
        } else {
          rethrow;
        }
      }
    }

    final errorStr = lastError.toString();
    if (errorStr.contains('object-not-found')) {
      throw 'Không tìm thấy Storage Bucket. Vui lòng đảm bảo bạn đã kích hoạt Firebase Storage bằng cách truy cập Firebase Console của dự án "mobile-e1ac5", vào phần "Storage" và bấm nút "Get Started" (Bắt đầu).';
    }
    throw lastError;
  }

  Future<bool> submit({
    required bool isEdit,
    required String? documentId,
    required bool isDocument,
    required String contentType,
    required String title,
    required String body,
    required String subjectCode,
    required String tagsText,
    required String externalUrl,
    String? placeId,
  }) async {
    if (isDocument) {
      if (localFileToUpload == null && uploadedFileUrl == null) {
        throw 'Vui lòng chọn tệp PDF tài liệu để tải lên!';
      }
    }

    loading = true;
    notifyListeners();

    try {
      String? finalFileUrl = uploadedFileUrl;

      if (isDocument && localFileToUpload != null) {
        uploading = true;
        uploadProgress = 0.0;
        notifyListeners();

        try {
          final remoteName = '${DateTime.now().millisecondsSinceEpoch}_$uploadedFileName';
          final downloadUrl = await _uploadToStorage(localFileToUpload!, remoteName);
          finalFileUrl = downloadUrl;

          uploadedFileUrl = downloadUrl;
          localFileToUpload = null;
          uploading = false;
          uploadProgress = 1.0;
          notifyListeners();
        } catch (e) {
          uploading = false;
          loading = false;
          notifyListeners();
          throw 'Tải tệp lên thất bại: $e';
        }
      }

      final tags = tagsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final payload = {
        'title': title,
        'body': body,
        'status': selectedStatus,
        'categoryId': selectedCategoryId,
        'type': contentType,
        if (isDocument && placeId != null && placeId.isNotEmpty) 'placeId': placeId,
        if (isDocument) ...{
          'fileUrl': finalFileUrl,
          'fileType': 'pdf',
          'fileSize': uploadedFileSize ?? 0,
          'subjectCode': subjectCode,
          'tags': tags,
        }
      };

      if (isEdit) {
        await SfinityApp.documentRepository.updateDocument(documentId!, payload);
      } else {
        await SfinityApp.documentRepository.createDocument(payload);
      }

      return true;
    } on DioException catch (e) {
      throw ApiClient.instance.errorMessage(e);
    } catch (e) {
      throw e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
