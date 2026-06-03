import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Phương tiện / kiểu chỉ đường.
enum RouteTravelMode {
  walking,
  motorcycle,
  car;

  /// Profile OSRM: `foot` (đi bộ), `driving` (xe máy & ô tô).
  String get osrmProfile => switch (this) {
        walking => 'foot',
        motorcycle => 'driving',
        car => 'driving',
      };

  /// Khóa cache — xe máy và ô tô dùng chung tuyến `driving`.
  String get cacheKey => osrmProfile;

  String get label => switch (this) {
        walking => 'Đi bộ',
        motorcycle => 'Xe máy',
        car => 'Ô tô',
      };

  IconData get icon => switch (this) {
        walking => Icons.directions_walk_rounded,
        motorcycle => Icons.two_wheeler_rounded,
        car => Icons.directions_car_rounded,
      };

  /// OSRM không có profile riêng cho xe máy — ước lượng nhanh hơn ô tô ~15%.
  double adjustDurationSeconds(double seconds) => switch (this) {
        motorcycle => seconds * 0.85,
        _ => seconds,
      };
}

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
    required this.travelMode,
  });

  final List<LatLng> polyline;
  final List<RouteStep> steps;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final LatLng origin;
  final LatLng destination;
  final RouteTravelMode travelMode;

  double get displayDurationSeconds =>
      travelMode.adjustDurationSeconds(totalDurationSeconds);
}
