import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/services/geocoding_service.dart';
import '../controllers/place_form_controller.dart';
import '../widgets/place_tag_chips.dart';

/// Chọn vị trí trên OSM và đăng / sửa địa điểm.
class PlaceSharePage extends StatefulWidget {
  const PlaceSharePage({super.key, this.editPlaceId});

  final String? editPlaceId;

  @override
  State<PlaceSharePage> createState() => _PlaceSharePageState();
}

class _PlaceSharePageState extends State<PlaceSharePage> {
  final _mapController = MapController();
  late final PlaceFormController _ctrl;
  bool _pickedFromRoute = false;
  bool _mapReady = false;

  bool get _isEdit => widget.editPlaceId != null && widget.editPlaceId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ctrl = PlaceFormController();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    if (_isEdit) {
      _ctrl.loadForEdit(widget.editPlaceId!).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      });
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
        _ctrl.setPickedFromCoords(lat.toDouble(), lng.toDouble());
        _pickedFromRoute = true;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng point) {
    _ctrl.onMapTap(point);
    if (_mapReady) {
      try {
        _mapController.move(point, _mapController.camera.zoom);
      } catch (_) {}
    }
  }

  void _selectSearchResult(GeocodingResult result) {
    _ctrl.selectSearchResult(result);
    final point = _ctrl.picked;
    if (_mapReady) {
      try {
        _mapController.move(point, 16);
      } catch (_) {}
    }
  }

  Future<void> _submit() async {
    try {
      await _ctrl.submit(editPlaceId: widget.editPlaceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Đã cập nhật địa điểm' : 'Đã lưu địa điểm')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl.loadingPlace) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Sửa địa điểm' : 'Lưu địa điểm')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final picked = MapConfig.sanitize(_ctrl.picked);

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
                    controller: _ctrl.searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên hoặc địa chỉ…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _ctrl.runSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _ctrl.runSearch,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          if (_ctrl.searchResults.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _ctrl.searchResults.length,
                itemBuilder: (_, i) {
                  final r = _ctrl.searchResults[i];
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
                if (_ctrl.geocodingAddress)
                  const Text('Đang lấy địa chỉ…', style: TextStyle(fontSize: 12))
                else if (_ctrl.address != null && _ctrl.address!.isNotEmpty)
                  Text(
                    _ctrl.address!,
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
                    controller: _ctrl.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên địa điểm',
                      border: OutlineInputBorder(),
                      hintText: 'VD: Thư viện, quán cà phê học nhóm',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl.descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả thêm (ghi chú, giờ mở cửa…)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  PlaceTagSelector(
                    selected: _ctrl.selectedTags,
                    onChanged: _ctrl.setSelectedTags,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ai có thể thấy địa điểm này?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Chỉ mình tôi'),
                        icon: Icon(Icons.lock_outline, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Cộng đồng'),
                        icon: Icon(Icons.public, size: 18),
                      ),
                    ],
                    selected: {_ctrl.isPublic},
                    onSelectionChanged: (selection) {
                      _ctrl.setIsPublic(selection.first);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ctrl.isPublic
                        ? 'Địa điểm hiển thị trên bản đồ cộng đồng cho mọi người.'
                        : 'Chỉ bạn thấy trong tab Của tôi, không hiện trên bản đồ cộng đồng.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _ctrl.loading ? null : _submit,
                    child: Text(
                      _ctrl.loading
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
