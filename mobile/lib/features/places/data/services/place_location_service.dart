import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../models/place_model.dart';

/// Vị trí GPS hiện tại kèm độ chính xác (mét).
class CurrentLocationReading {
  const CurrentLocationReading({
    required this.point,
    required this.accuracyM,
  });

  final LatLng point;
  final double accuracyM;
}

/// GPS / quyền vị trí cho tab địa điểm.
class PlaceLocationService {
  Future<LatLng?> getCurrentLocation() async {
    final reading = await getCurrentLocationReading();
    return reading?.point;
  }

  Future<CurrentLocationReading?> getCurrentLocationReading() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = MapConfig.latLngFromCoords(
        current.latitude,
        current.longitude,
      );
      if (point == null) return null;
      final accuracy = current.accuracy;
      if (!accuracy.isFinite || accuracy <= 0) return null;
      return CurrentLocationReading(point: point, accuracyM: accuracy);
    } catch (_) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          final point = MapConfig.latLngFromCoords(
            lastKnown.latitude,
            lastKnown.longitude,
          );
          final accuracy = lastKnown.accuracy;
          if (point != null &&
              accuracy.isFinite &&
              accuracy > 0 &&
              accuracy <= 25) {
            return CurrentLocationReading(point: point, accuracyM: accuracy);
          }
        }
      } catch (_) {}
      return null;
    }
  }

  String distanceLabel(LatLng from, LatLng to) {
    final meters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String formatDistanceMeters(int? meters) {
    if (meters == null) return '';
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  List<PlaceModel> sortByDistance(
    List<PlaceModel> places,
    LatLng? userLocation,
  ) {
    if (userLocation == null) return places;
    final sorted = [...places];
    sorted.sort((a, b) {
      final pa = a.point;
      final pb = b.point;
      if (pa == null || pb == null) return 0;
      final da = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        pa.latitude,
        pa.longitude,
      );
      final db = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        pb.latitude,
        pb.longitude,
      );
      return da.compareTo(db);
    });
    return sorted;
  }
}
