import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/constants/route_names.dart';

/// Bản đồ địa điểm — tile OpenStreetMap (open source).
class PlacesMapPage extends StatefulWidget {
  const PlacesMapPage({super.key});

  @override
  State<PlacesMapPage> createState() => _PlacesMapPageState();
}

class _PlacesMapPageState extends State<PlacesMapPage> {
  final _mapController = MapController();
  LatLng _center = MapConfig.defaultCenter;
  bool _locating = false;
  bool _mapReady = false;
  String? _locationHint;

  static final _demoPlaces = <({String title, String subtitle, LatLng point})>[
    (title: 'Thư viện TP.HCM', subtitle: '69 Lý Tự Trọng', point: LatLng(10.7798, 106.6992)),
    (title: 'Khu học nhóm Bách Khoa', subtitle: 'Gần ĐHQG', point: LatLng(10.7720, 106.6583)),
    (title: 'Không gian làm việc chung', subtitle: 'Quận 3', point: LatLng(10.7860, 106.6880)),
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _safeMove(LatLng target, double zoom) {
    if (!MapConfig.isValidLatLng(target) || !_mapReady) return;
    try {
      _mapController.move(target, zoom);
    } catch (_) {
      // Map chưa sẵn sàng hoặc camera không hợp lệ — bỏ qua.
    }
  }

  Future<LatLng?> _resolveUserLocation() async {
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
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );
    final fromCurrent = MapConfig.latLngFromCoords(
      current.latitude,
      current.longitude,
    );
    if (fromCurrent != null) return fromCurrent;

    final last = await Geolocator.getLastKnownPosition();
    if (last == null) return null;
    return MapConfig.latLngFromCoords(last.latitude, last.longitude);
  }

  Future<void> _initLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationHint = null;
    });

    try {
      final here = await _resolveUserLocation();
      if (!mounted) return;

      if (here == null) {
        setState(() {
          _locating = false;
          _locationHint = 'Bật quyền vị trí hoặc thử lại để xem vị trí của bạn';
        });
        return;
      }

      setState(() {
        _center = here;
        _locating = false;
      });
      _safeMove(here, MapConfig.defaultZoom);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locating = false;
          _locationHint = 'Không lấy được vị trí — hiển thị bản đồ mặc định';
        });
      }
    }
  }

  void _goToUserLocation() => _initLocation();

  void _onMapTap(LatLng point) {
    if (!MapConfig.isValidLatLng(point)) return;
    _showPlaceSheet(
      context,
      'Điểm trên bản đồ',
      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
      point,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = MapConfig.sanitize(_center);

    final markers = <Marker>[
      for (final p in _demoPlaces)
        Marker(
          point: p.point,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showPlaceSheet(context, p.title, p.subtitle, p.point),
            child: const Icon(Icons.place, color: Color(0xFFE53935), size: 36),
          ),
        ),
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: MapConfig.defaultZoom,
            onMapReady: () {
              _mapReady = true;
              if (MapConfig.isValidLatLng(_center) &&
                  _center != MapConfig.defaultCenter) {
                _safeMove(_center, MapConfig.defaultZoom);
              }
            },
            onTap: (_, point) => _onMapTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileUrlTemplate,
              userAgentPackageName: MapConfig.userAgentPackageName,
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        if (_locating)
          const Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Đang định vị…'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_locationHint != null && !_locating)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_locationHint!, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'share_place',
                onPressed: () => context.push(RouteNames.placeShare),
                child: const Icon(Icons.add_location_alt_outlined),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'my_location',
                onPressed: _locating ? null : _goToUserLocation,
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          bottom: 96,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPlaceSheet(BuildContext context, String title, String subtitle, LatLng point) {
    if (!MapConfig.isValidLatLng(point)) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(subtitle),
              const SizedBox(height: 8),
              Text(
                'Tọa độ: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.placeShare, extra: {
                    'lat': point.latitude,
                    'lng': point.longitude,
                  });
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Chia sẻ địa điểm này'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
