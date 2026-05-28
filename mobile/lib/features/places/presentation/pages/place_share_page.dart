import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/network/api_client.dart';

/// Chọn vị trí trên OSM và đăng chia sẻ địa điểm.
class PlaceSharePage extends StatefulWidget {
  const PlaceSharePage({super.key});

  @override
  State<PlaceSharePage> createState() => _PlaceSharePageState();
}

class _PlaceSharePageState extends State<PlaceSharePage> {
  final _mapController = MapController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  LatLng _picked = MapConfig.defaultCenter;
  bool _loading = false;
  bool _pickedFromRoute = false;
  bool _mapReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pickedFromRoute) return;
    final extra = GoRouterState.of(context).extra;
    if (extra is Map) {
      final lat = extra['lat'];
      final lng = extra['lng'];
      if (lat is num && lng is num) {
        final fromRoute = MapConfig.latLngFromCoords(lat.toDouble(), lng.toDouble());
        if (fromRoute != null) {
          _picked = fromRoute;
          _pickedFromRoute = true;
        }
      }
    }
  }

  void _onMapTap(LatLng point) {
    if (!MapConfig.isValidLatLng(point)) return;
    setState(() => _picked = point);
    if (_mapReady) {
      try {
        _mapController.move(point, _mapController.camera.zoom);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tên địa điểm')),
      );
      return;
    }
    if (!MapConfig.isValidLatLng(_picked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn vị trí hợp lệ trên bản đồ')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiClient.instance.post('/document', {
        'title': _name.text.trim(),
        'body': _description.text.trim().isEmpty
            ? 'Địa điểm học tập do người dùng chia sẻ.'
            : _description.text.trim(),
        'type': 'place',
        'latitude': _picked.latitude,
        'longitude': _picked.longitude,
        'address':
            '${_picked.latitude.toStringAsFixed(5)}, ${_picked.longitude.toStringAsFixed(5)}',
        'status': 'PUBLISHED',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu địa điểm')),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final picked = MapConfig.sanitize(_picked);

    return Scaffold(
      appBar: AppBar(title: const Text('Lưu địa điểm')),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: picked,
                initialZoom: 15,
                onMapReady: () => _mapReady = true,
                onTap: (_, point) => _onMapTap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.tileUrlTemplate,
                  userAgentPackageName: MapConfig.userAgentPackageName,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: picked,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.place, color: Color(0xFFE53935), size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Chạm bản đồ để chọn vị trí · ${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Tên địa điểm',
                      border: OutlineInputBorder(),
                      hintText: 'VD: Thư viện, quán cà phê học nhóm',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả (WiFi, ổ cắm, giờ mở cửa…)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? 'Đang lưu…' : 'Lưu địa điểm'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
