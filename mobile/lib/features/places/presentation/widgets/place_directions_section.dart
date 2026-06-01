import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../data/models/place_route_model.dart';
import '../../data/services/place_location_service.dart';
import '../../data/services/place_routing_service.dart';

/// Bản đồ + hướng dẫn đi từ GPS hiện tại tới địa điểm.
class PlaceDirectionsSection extends StatefulWidget {
  const PlaceDirectionsSection({
    super.key,
    required this.destination,
    required this.accentColor,
  });

  final LatLng destination;
  final Color accentColor;

  @override
  State<PlaceDirectionsSection> createState() => _PlaceDirectionsSectionState();
}

class _PlaceDirectionsSectionState extends State<PlaceDirectionsSection> {
  final _mapController = MapController();
  final _locationService = PlaceLocationService();
  final _routingService = PlaceRoutingService();

  bool _expanded = false;
  bool _loading = false;
  String? _error;
  PlaceRouteResult? _route;

  Future<void> _loadDirections() async {
    setState(() {
      _loading = true;
      _error = null;
      _expanded = true;
    });

    try {
      final origin = await _locationService.getCurrentLocation();
      if (origin == null) {
        setState(() {
          _loading = false;
          _error =
              'Không lấy được vị trí GPS. Bật định vị và cấp quyền cho ứng dụng.';
        });
        return;
      }

      final route = await _routingService.fetchRoute(
        origin: origin,
        destination: widget.destination,
      );

      if (!mounted) return;
      setState(() {
        _route = route;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRouteOnMap(route));
    } on PlaceRoutingException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được chỉ đường. Kiểm tra mạng và thử lại.';
      });
    }
  }

  void _fitRouteOnMap(PlaceRouteResult route) {
    try {
      final points = [
        route.origin,
        route.destination,
        ...route.polyline,
      ];
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
        ),
      );
    } catch (_) {}
  }

  void _collapse() {
    setState(() {
      _expanded = false;
      _route = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_expanded) {
      return FilledButton.icon(
        onPressed: _loadDirections,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.directions_rounded),
        label: const Text(
          'Dẫn đường từ vị trí của tôi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Chỉ đường',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Đóng',
              onPressed: _collapse,
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: _buildMap(isDark),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _ErrorBox(
            message: _error!,
            onRetry: _loadDirections,
          )
        else if (_route != null)
          _RouteSummary(
            route: _route!,
            locationService: _locationService,
            isDark: isDark,
            accentColor: widget.accentColor,
          ),
        if (_route != null) ...[
          const SizedBox(height: 12),
          Text(
            'Các bước đi',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._route!.steps.asMap().entries.map(
                (e) => _StepTile(
                  index: e.key + 1,
                  step: e.value,
                  isLast: e.key == _route!.steps.length - 1,
                  isDark: isDark,
                  accentColor: widget.accentColor,
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildMap(bool isDark) {
    final route = _route;
    final center = route?.polyline.isNotEmpty == true
        ? route!.polyline[route.polyline.length ~/ 2]
        : widget.destination;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrlTemplate,
          userAgentPackageName: MapConfig.userAgentPackageName,
        ),
        if (route != null) ...[
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.polyline,
                color: widget.accentColor,
                strokeWidth: 5,
                borderColor: Colors.white.withValues(alpha: 0.9),
                borderStrokeWidth: 2,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: route.origin,
                width: 36,
                height: 36,
                child: _MapDot(
                  color: Colors.blue.shade600,
                  icon: Icons.my_location,
                ),
              ),
              Marker(
                point: route.destination,
                width: 36,
                height: 36,
                child: _MapDot(
                  color: widget.accentColor,
                  icon: Icons.place_rounded,
                ),
              ),
            ],
          ),
        ] else
          MarkerLayer(
            markers: [
              Marker(
                point: widget.destination,
                width: 36,
                height: 36,
                child: _MapDot(
                  color: widget.accentColor,
                  icon: Icons.place_rounded,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _MapDot extends StatelessWidget {
  const _MapDot({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({
    required this.route,
    required this.locationService,
    required this.isDark,
    required this.accentColor,
  });

  final PlaceRouteResult route;
  final PlaceLocationService locationService;
  final bool isDark;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final dist = locationService.formatDistanceMeters(route.totalDistanceMeters.round());
    final mins = (route.totalDurationSeconds / 60).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.route_outlined, color: accentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$dist · khoảng $mins phút',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.step,
    required this.isLast,
    required this.isDark,
    required this.accentColor,
  });

  final int index;
  final RouteStep step;
  final bool isLast;
  final bool isDark;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: index == 1
                      ? Colors.blue.shade600
                      : (isLast ? accentColor : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(step.icon),
                  size: 15,
                  color: index == 1 || isLast ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                step.instruction,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(RouteStepIcon icon) {
    return switch (icon) {
      RouteStepIcon.depart => Icons.trip_origin,
      RouteStepIcon.arrive => Icons.flag_rounded,
      RouteStepIcon.straight => Icons.arrow_upward_rounded,
      RouteStepIcon.turnLeft => Icons.turn_left_rounded,
      RouteStepIcon.turnRight => Icons.turn_right_rounded,
      RouteStepIcon.slightLeft => Icons.turn_slight_left_rounded,
      RouteStepIcon.slightRight => Icons.turn_slight_right_rounded,
      RouteStepIcon.sharpLeft => Icons.turn_sharp_left_rounded,
      RouteStepIcon.sharpRight => Icons.turn_sharp_right_rounded,
      RouteStepIcon.uturn => Icons.u_turn_left_rounded,
      RouteStepIcon.roundabout => Icons.roundabout_left_rounded,
      RouteStepIcon.merge => Icons.merge_rounded,
      RouteStepIcon.fork => Icons.call_split_rounded,
      RouteStepIcon.other => Icons.navigation_outlined,
    };
  }
}
