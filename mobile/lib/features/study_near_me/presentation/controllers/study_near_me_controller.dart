import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/study_near_me_result.dart';

class StudyNearMeController extends ChangeNotifier {
  bool loading = false;
  String? error;
  StudyNearMeResult? result;

  Future<bool> loadNearby({LatLng? location, double? radiusKm}) async {
    loading = true;
    error = null;
    result = null;
    notifyListeners();

    try {
      LatLng? here = location;
      here ??= await SfinityApp.studyNearMeRepository.getCurrentLocation();
      if (here == null) {
        error = 'Bật GPS/quyền vị trí để dùng Học gần tôi';
        loading = false;
        notifyListeners();
        return false;
      }

      result = await SfinityApp.studyNearMeRepository.findNearby(
        location: here,
        radiusKm: radiusKm,
      );
      loading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
    return false;
  }

  void reset() {
    loading = false;
    error = null;
    result = null;
    notifyListeners();
  }
}
