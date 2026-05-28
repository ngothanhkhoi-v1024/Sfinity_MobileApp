import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/geocoding_service.dart';

/// Chọn vị trí trên OSM và đăng / sửa địa điểm.
class PlaceSharePage extends StatefulWidget {
  const PlaceSharePage({super.key, this.editPlaceId});

  final String? editPlaceId;

  @override
  State<PlaceSharePage> createState() => _PlaceSharePageState();
}

class _PlaceSharePageState extends State<PlaceSharePage> {
  final _mapController = MapController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _search = TextEditingController();
  final _geocoding = GeocodingService();
  LatLng _picked = MapConfig.defaultCenter;
  String? _address;
  bool _loading = false;
  bool _loadingPlace = false;
  bool _geocodingAddress = false;
  bool _pickedFromRoute = false;
  bool _mapReady = false;
  List<GeocodingResult> _searchResults = [];

  bool get _isEdit => widget.editPlaceId != null && widget.editPlaceId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadExisting();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pickedFromRoute || _isEdit) return;
    final extra = GoRouterState.of(context).extra;
    if (extra is Map) {
      final lat = extra['lat'];
      final lng = extra['lng'];
      if (lat is num && lng is num) {
        final fromRoute = MapConfig.latLngFromCoords(lat.toDouble(), lng.toDouble());
        if (fromRoute != null) {
          _picked = fromRoute;
          _pickedFromRoute = true;
          _resolveAddress(fromRoute);
        }
      }
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingPlace = true);
    try {
      final data = await ApiClient.instance.get('/document/${widget.editPlaceId}');
      final lat = data['latitude'];
      final lng = data['longitude'];
      if (lat is num && lng is num) {
        final point = MapConfig.latLngFromCoords(lat.toDouble(), lng.toDouble());
        if (point != null) _picked = point;
      }
      _name.text = data['title']?.toString() ?? '';
      _description.text = data['body']?.toString() ?? '';
      _address = data['address']?.toString();
      if (_address == null || _address!.isEmpty) {
        await _resolveAddress(_picked);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPlace = false);
    }
  }

  Future<void> _resolveAddress(LatLng point) async {
    setState(() => _geocodingAddress = true);
    final addr = await _geocoding.reverseAddress(point.latitude, point.longitude);
    if (mounted) {
      setState(() {
        _address = addr;
        _geocodingAddress = false;
      });
    }
  }

  void _onMapTap(LatLng point) {
    if (!MapConfig.isValidLatLng(point)) return;
    setState(() {
      _picked = point;
      _searchResults = [];
    });
    _resolveAddress(point);
    if (_mapReady) {
      try {
        _mapController.move(point, _mapController.camera.zoom);
      } catch (_) {}
    }
  }

  Future<void> _runSearch() async {
    final results = await _geocoding.search(_search.text);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  void _selectSearchResult(GeocodingResult result) {
    final lat = result.lat;
    final lng = result.lng;
    if (lat == null || lng == null) return;
    final point = MapConfig.latLngFromCoords(lat, lng);
    if (point == null) return;
    setState(() {
      _picked = point;
      _address = result.displayName;
      _searchResults = [];
      _search.text = result.displayName;
    });
    if (_mapReady) {
      try {
        _mapController.move(point, 16);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _search.dispose();
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
      final payload = {
        'title': _name.text.trim(),
        'body': _description.text.trim().isEmpty
            ? 'Địa điểm học tập do người dùng chia sẻ.'
            : _description.text.trim(),
        'type': 'place',
        'latitude': _picked.latitude,
        'longitude': _picked.longitude,
        'address': _address ??
            '${_picked.latitude.toStringAsFixed(5)}, ${_picked.longitude.toStringAsFixed(5)}',
        'status': 'PUBLISHED',
      };
      if (_isEdit) {
        await ApiClient.instance.patch('/document/${widget.editPlaceId}', payload);
      } else {
        await ApiClient.instance.post('/document', payload);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Đã cập nhật địa điểm' : 'Đã lưu địa điểm')),
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
    if (_loadingPlace) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Sửa địa điểm' : 'Lưu địa điểm')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final picked = MapConfig.sanitize(_picked);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa địa điểm' : 'Lưu địa điểm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên hoặc địa chỉ…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _runSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _runSearch,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          if (_searchResults.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _searchResults.length,
                itemBuilder: (_, i) {
                  final r = _searchResults[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined, size: 20),
                    title: Text(
                      r.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () => _selectSearchResult(r),
                  );
                },
              ),
            ),
          SizedBox(
            height: 200,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_geocodingAddress)
                  const Text('Đang lấy địa chỉ…', style: TextStyle(fontSize: 12))
                else if (_address != null && _address!.isNotEmpty)
                  Text(
                    _address!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  )
                else
                  Text(
                    'Chạm bản đồ để chọn vị trí · ${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
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
                    child: Text(
                      _loading
                          ? 'Đang lưu…'
                          : (_isEdit ? 'Cập nhật địa điểm' : 'Lưu địa điểm'),
                    ),
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
