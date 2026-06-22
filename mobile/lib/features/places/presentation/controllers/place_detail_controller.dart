import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/place_model.dart';

/// Tạm tắt — phần tài liệu tại địa điểm đang lỗi.
const kPlaceDocumentsEnabled = false;

class PlaceDetailController extends ChangeNotifier {
  PlaceModel? place;
  List<Map<String, dynamic>> documents = [];
  bool loading = true;
  String? error;

  Future<void> load(String placeId, {String Function()? placeNotFound}) async {
    loading = true;
    error = null;
    documents = [];
    notifyListeners();

    try {
      place = await SfinityApp.placeRepository.getPlace(
        placeId,
        placeNotFound: placeNotFound,
      );
      loading = false;
      notifyListeners();

      if (kPlaceDocumentsEnabled) {
        documents = await SfinityApp.placeRepository.listDocumentsAtPlace(placeId);
        notifyListeners();
      }
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
      loading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  bool isMine() {
    final p = place;
    if (p == null) return false;
    final currentUserId = SfinityApp.auth.user?['id']?.toString();
    return currentUserId != null &&
        p.authorId != null &&
        currentUserId == p.authorId;
  }

  Future<bool> deletePlace(String placeId) async {
    try {
      await SfinityApp.placeRepository.deletePlace(placeId);
      return true;
    } on DioException {
      rethrow;
    }
  }
}
