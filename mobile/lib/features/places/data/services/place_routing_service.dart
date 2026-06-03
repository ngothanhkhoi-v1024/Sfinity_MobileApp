import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/i18n/app_text.dart';
import '../models/place_route_model.dart';

class PlaceRoutingService {
  PlaceRoutingService({Dio? dio}) : _dio = dio ?? Dio(_defaultOptions);

  static final _defaultOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'User-Agent': MapConfig.userAgentPackageName},
  );

  final Dio _dio;

  Future<PlaceRouteResult> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    required RouteTravelMode travelMode,
    required String Function() noPathFound,
    required String Function() noSuitableRoute,
    required String Function() invalidRouteData,
  }) async {
    final coords =
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
    final profiles = travelMode == RouteTravelMode.walking
        ? ['foot', 'walking']
        : [travelMode.osrmProfile];

    Map<String, dynamic>? data;
    Object? lastError;
    for (final profile in profiles) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          '${MapConfig.osrmBaseUrl}/route/v1/$profile/$coords',
          queryParameters: const {
            'overview': 'full',
            'geometries': 'geojson',
            'steps': 'true',
            'alternatives': 'false',
          },
        );
        final body = response.data;
        if (body != null && body['code'] == 'Ok') {
          data = body;
          break;
        }
        lastError = body?['message']?.toString();
      } on DioException catch (e) {
        lastError = e;
      }
    }

    if (data == null) {
      throw PlaceRoutingException(noPathFound());
    }

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw PlaceRoutingException(noSuitableRoute());
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>?;
    final rawCoords = geometry?['coordinates'] as List<dynamic>? ?? [];

    final polyline = rawCoords
        .map((c) {
          final pair = c as List<dynamic>;
          return LatLng(
            (pair[1] as num).toDouble(),
            (pair[0] as num).toDouble(),
          );
        })
        .where(MapConfig.isValidLatLng)
        .toList();

    if (polyline.isEmpty) {
      throw PlaceRoutingException(invalidRouteData());
    }

    final legs = route['legs'] as List<dynamic>? ?? [];
    final steps = <RouteStep>[];
    for (final leg in legs) {
      final legMap = leg as Map<String, dynamic>;
      final legSteps = legMap['steps'] as List<dynamic>? ?? [];
      for (final raw in legSteps) {
        final step = raw as Map<String, dynamic>;
        final parsed = _parseStep(step);
        if (parsed != null) steps.add(parsed);
      }
    }

    return PlaceRouteResult(
      polyline: polyline,
      steps: steps,
      totalDistanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
      totalDurationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      origin: origin,
      destination: destination,
      travelMode: travelMode,
    );
  }

  RouteStep? _parseStep(Map<String, dynamic> step) {
    final distance = (step['distance'] as num?)?.toDouble() ?? 0;
    final duration = (step['duration'] as num?)?.toDouble();
    final name = (step['name'] as String?)?.trim() ?? '';
    final maneuver = step['maneuver'] as Map<String, dynamic>?;
    final type = maneuver?['type'] as String? ?? '';
    final modifier = maneuver?['modifier'] as String? ?? '';

    final icon = _iconForManeuver(type, modifier);
    final action = _maneuverLabel(type, modifier);
    final dist = _formatStepDistance(distance);

    String instruction;
    if (type == 'arrive') {
      instruction = 'Arrive';
    } else if (name.isNotEmpty) {
      instruction = '$action — $name · $dist';
    } else {
      instruction = '$action · $dist';
    }

    return RouteStep(
      instruction: instruction,
      distanceMeters: distance,
      durationSeconds: duration,
      icon: icon,
    );
  }

  static RouteStepIcon _iconForManeuver(String type, String modifier) {
    if (type == 'depart') return RouteStepIcon.depart;
    if (type == 'arrive') return RouteStepIcon.arrive;
    if (type.contains('roundabout') || type == 'rotary') {
      return RouteStepIcon.roundabout;
    }
    if (type == 'merge') return RouteStepIcon.merge;
    if (type == 'fork') return RouteStepIcon.fork;
    return switch (modifier) {
      'left' => RouteStepIcon.turnLeft,
      'right' => RouteStepIcon.turnRight,
      'slight left' => RouteStepIcon.slightLeft,
      'slight right' => RouteStepIcon.slightRight,
      'sharp left' => RouteStepIcon.sharpLeft,
      'sharp right' => RouteStepIcon.sharpRight,
      'uturn' => RouteStepIcon.uturn,
      'straight' => RouteStepIcon.straight,
      _ => RouteStepIcon.other,
    };
  }

  static String _maneuverLabel(String type, String modifier) {
    if (type == 'depart') return 'Start';
    if (type == 'arrive') return 'Arrive';
    if (type == 'roundabout' || type == 'rotary') return 'Enter roundabout';
    if (type == 'exit roundabout' || type == 'exit rotary') {
      return 'Exit roundabout';
    }
    if (type == 'merge') return 'Merge';
    if (type == 'fork') return 'Fork';
    if (type == 'end of road') {
      return modifier.contains('left') ? 'End of road, turn left' : 'End of road, turn right';
    }
    if (type == 'new name' || type == 'continue') return 'Continue straight';
    if (type == 'on ramp') return 'Enter ramp';
    if (type == 'off ramp') return 'Exit ramp';

    return switch (modifier) {
      'left' => 'Turn left',
      'right' => 'Turn right',
      'slight left' => 'Slight left',
      'slight right' => 'Slight right',
      'sharp left' => 'Sharp left',
      'sharp right' => 'Sharp right',
      'uturn' => 'U-turn',
      'straight' => 'Go straight',
      _ => 'Continue',
    };
  }

  static String _formatStepDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class PlaceRoutingException implements Exception {
  const PlaceRoutingException(this.message);
  final String message;

  @override
  String toString() => message;
}
