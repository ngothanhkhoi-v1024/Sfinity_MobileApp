import 'package:geolocator/geolocator.dart';

/// Check-in geofence: distance <= max(10m, GPS accuracy), accuracy <= 25m.
abstract final class PlaceCheckInGeo {
  static const maxAccuracyM = 25.0;
  static const baseRadiusM = 10.0;

  static double allowedRadiusM(double accuracyM) {
    if (accuracyM <= 0 || accuracyM > maxAccuracyM) return 0;
    return accuracyM > baseRadiusM ? accuracyM : baseRadiusM;
  }

  static bool isWithinRadius({
    required double distanceM,
    required double accuracyM,
  }) {
    if (accuracyM <= 0 || accuracyM > maxAccuracyM) return false;
    return distanceM <= allowedRadiusM(accuracyM);
  }

  static double distanceM({
    required double userLat,
    required double userLng,
    required double placeLat,
    required double placeLng,
  }) {
    return Geolocator.distanceBetween(userLat, userLng, placeLat, placeLng);
  }
}
