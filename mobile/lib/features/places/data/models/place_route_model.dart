import 'package:latlong2/latlong.dart';

/// Một bước chỉ đường (rẽ trái, đi thẳng, …).
class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    this.durationSeconds,
    required this.icon,
  });

  final String instruction;
  final double distanceMeters;
  final double? durationSeconds;
  final RouteStepIcon icon;
}

enum RouteStepIcon {
  depart,
  arrive,
  straight,
  turnLeft,
  turnRight,
  slightLeft,
  slightRight,
  sharpLeft,
  sharpRight,
  uturn,
  roundabout,
  merge,
  fork,
  other,
}

/// Kết quả tuyến từ GPS hiện tại tới địa điểm.
class PlaceRouteResult {
  const PlaceRouteResult({
    required this.polyline,
    required this.steps,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.origin,
    required this.destination,
  });

  final List<LatLng> polyline;
  final List<RouteStep> steps;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final LatLng origin;
  final LatLng destination;
}
