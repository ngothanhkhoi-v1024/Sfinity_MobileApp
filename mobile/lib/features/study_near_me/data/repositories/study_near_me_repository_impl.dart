import 'package:latlong2/latlong.dart';

import '../../../places/data/services/place_location_service.dart';
import '../models/study_near_me_result.dart';
import '../services/study_near_me_api_service.dart';
import 'study_near_me_repository.dart';

/// Bán kính mặc định "Học gần tôi".
const studyNearMeDefaultRadiusKm = 3.0;

class StudyNearMeRepositoryImpl implements StudyNearMeRepository {
  StudyNearMeRepositoryImpl(this._api, this._location);

  final StudyNearMeApiService _api;
  final PlaceLocationService _location;

  @override
  Future<StudyNearMeResult> findNearby({
    required LatLng location,
    double? radiusKm,
  }) async {
    final res = await _api.findNearby(
      lat: location.latitude,
      lng: location.longitude,
      radiusKm: radiusKm ?? studyNearMeDefaultRadiusKm,
      limit: 40,
    );
    return StudyNearMeResult.fromJson(Map<String, dynamic>.from(res));
  }

  @override
  Future<LatLng?> getCurrentLocation() => _location.getCurrentLocation();
}
