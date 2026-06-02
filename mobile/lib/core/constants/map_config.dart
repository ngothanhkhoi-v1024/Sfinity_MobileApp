import 'package:latlong2/latlong.dart';

/// OpenStreetMap tile layer (open source).
abstract final class MapConfig {
  static const tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgentPackageName = 'com.sfinity.sfinity';

  /// OSRM public router (OpenStreetMap).
  static const osrmBaseUrl = 'https://router.project-osrm.org';

  /// Trung tâm mặc định (TP.HCM) khi chưa có GPS.
  static const defaultCenter = LatLng(10.8231, 106.6297);
  static const defaultZoom = 13.0;

  static bool isValidLatLng(LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  static LatLng? latLngFromCoords(double latitude, double longitude) {
    final point = LatLng(latitude, longitude);
    return isValidLatLng(point) ? point : null;
  }

  static LatLng sanitize(LatLng point) =>
      isValidLatLng(point) ? point : defaultCenter;
}
