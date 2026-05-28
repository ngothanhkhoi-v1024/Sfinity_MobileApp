import 'package:latlong2/latlong.dart';

import '../models/study_near_me_result.dart';

abstract class StudyNearMeRepository {
  Future<StudyNearMeResult> findNearby({
    required LatLng location,
    double? radiusKm,
  });

  Future<LatLng?> getCurrentLocation();
}
