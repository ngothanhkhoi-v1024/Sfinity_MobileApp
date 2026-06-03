import 'dart:io';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../i18n/app_text.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  void setToken(String? token) {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get<dynamic>(path, queryParameters: query);
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await _dio.post<dynamic>(path, data: body);
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final res = await _dio.patch<dynamic>(path, data: body);
    return _asMap(res.data);
  }

  Future<void> delete(String path) async {
    await _dio.delete<dynamic>(path);
  }

  Future<String> uploadFile(File file, {String fieldName = 'file'}) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(file.path),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/upload/image',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    final data = res.data;
    if (data == null) throw Exception('Upload thất bại: không có phản hồi từ server');
    final url = data['url'];
    if (url == null || url.toString().isEmpty) {
      throw Exception('Upload thất bại: server không trả về URL');
    }
    return url.toString();
  }

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get<dynamic>(path, queryParameters: query);
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return [];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  String errorMessage(DioException e, {AppLocalizations? l10n}) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
      if (msg is String) return msg;
    }
    return l10n?.apiError ?? 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
}
