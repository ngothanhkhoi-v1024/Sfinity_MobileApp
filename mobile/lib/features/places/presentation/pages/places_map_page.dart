import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/place_model.dart';
import '../controllers/places_map_controller.dart';
import '../widgets/place_list_tile.dart';
import '../widgets/place_tag_chips.dart';
import '../widgets/places_header_panel.dart';

/// Bản đồ địa điểm — tile OpenStreetMap (open source).
class PlacesMapPage extends StatefulWidget {
  const PlacesMapPage({super.key});

  @override
  State<PlacesMapPage> createState() => _PlacesMapPageState();
}

class _PlacesMapPageState extends State<PlacesMapPage> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  late final PlacesMapController _ctrl;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _ctrl = PlacesMapController();
    _ctrl.addListener(_onControllerUpdate);
    _ctrl.init();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _safeMove(LatLng target, double zoom) {
    if (!MapConfig.isValidLatLng(target) || !_mapReady) return;
    try {
      _mapController.move(target, zoom);
    } catch (_) {}
  }

  void _focusPlaceOnMap(PlaceModel place) {
    final point = place.point;
    if (point == null) return;
    _ctrl.setListView(false);
    _safeMove(point, 15);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showPlaceSheet(place, point);
    });
  }

  Future<void> _deletePlace(String placeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa địa điểm?'),
        content: const Text('Bạn có chắc muốn xóa địa điểm này khỏi bản đồ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _ctrl.deletePlace(placeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa địa điểm')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    }
  }

  void _showPickLocationSheet(LatLng point) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lưu địa điểm mới', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Tọa độ đã chọn: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context
                      .push(RouteNames.placeShare, extra: {
                        'lat': point.latitude,
                        'lng': point.longitude,
                      })
                      .then((_) => _ctrl.loadPlaces());
                },
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Lưu địa điểm này'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaceSheet(PlaceModel place, LatLng point) {
    final distanceText = place.distanceMeters != null
        ? _ctrl.distanceLabelFor(place)
        : _ctrl.distanceLabelFor(place);

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (place.address != null && place.address!.isNotEmpty)
                Text(place.address!, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              PlaceTagDisplay(tagIds: place.tags),
              if (place.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(place.body, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Text(
                'Khoảng cách: $distanceText',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: place.id.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        context.push('/places/${place.id}');
                      },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Xem chi tiết địa điểm'),
              ),
              if (_ctrl.isOwnedByCurrentUser(place) && place.id.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(
                      RouteNames.documentCreate,
                      extra: {
                        'contentType': 'document',
                        'placeId': place.id,
                        'placeTitle': place.title,
                      },
                    );
                  },
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Tải tài liệu'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/places/${place.id}/edit').then((_) => _ctrl.loadPlaces());
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Sửa địa điểm'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deletePlace(place.id);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Xóa địa điểm', style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm địa điểm theo tên hoặc địa chỉ…',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onSubmitted: (_) {
          _ctrl.setSearchQuery(_searchController.text);
          _ctrl.loadPlaces();
        },
      ),
    );
  }

  Widget _buildTagFilterBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PlaceTagFilterBar(
        selected: _ctrl.filterTags,
        onChanged: (v) {
          _ctrl.setFilterTags(v);
        },
        onApply: () {
          _ctrl.setSearchQuery(_searchController.text);
          _ctrl.loadPlaces();
        },
      ),
    );
  }

  Widget _buildHeader() {
    return PlacesHeaderPanel(
      communityMode: _ctrl.communityMode,
      listView: _ctrl.listView,
      onCommunityChanged: _ctrl.setCommunityMode,
      onViewChanged: _ctrl.setListView,
    );
  }

  Widget _buildListSectionHeader(int count) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ctrl.communityMode ? 'Địa điểm cộng đồng' : 'Địa điểm của bạn',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _ctrl.listSectionSubtitle(count),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (_ctrl.myLocation != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.near_me, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Gần bạn',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlacesList(List<PlaceModel> places, {required bool listMode}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sorted = _ctrl.sortedActivePlaces();

    if (_ctrl.loadingPlaces) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 48,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                _ctrl.communityMode ? 'Chưa có địa điểm cộng đồng' : 'Chưa có địa điểm',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _ctrl.communityMode
                    ? 'Lưu địa điểm đầu tiên bằng nút + hoặc chạm bản đồ.'
                    : 'Chạm bản đồ hoặc nút + để thêm địa điểm.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, listMode ? 0 : 8, 16, 100),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final place = sorted[i];
        return PlaceListTile(
          title: place.title,
          subtitle: _ctrl.subtitleFor(place),
          distanceLabel: _ctrl.distanceLabelFor(place),
          isCommunity: _ctrl.communityMode,
          onTap: () => context.push('/places/${place.id}'),
          showMapAction: listMode,
          onMapTap: listMode ? () => _focusPlaceOnMap(place) : null,
        );
      },
    );
  }

  Widget _buildListViewLayout() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F6F8);
    final sorted = _ctrl.sortedActivePlaces();

    return ColoredBox(
      color: sheetBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildTagFilterBar(),
              ],
            ),
          ),
          if (_ctrl.locationHint != null && !_ctrl.locating)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _HintBanner(message: _ctrl.locationHint!),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _buildListSectionHeader(sorted.length),
                  Expanded(child: _buildPlacesList(sorted, listMode: true)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'refresh_places',
          onPressed: () {
            _ctrl.setSearchQuery(_searchController.text);
            _ctrl.loadPlaces();
          },
          child: const Icon(Icons.refresh),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'add_place',
          onPressed: () => context.push(RouteNames.placeShare).then((_) => _ctrl.loadPlaces()),
          child: const Icon(Icons.add_location_alt_outlined),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'my_location',
          onPressed: _ctrl.locating
              ? null
              : () async {
                  await _ctrl.initLocation();
                  final here = _ctrl.myLocation;
                  if (here != null) _safeMove(here, 14);
                },
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = _ctrl.activePlaces;
    final mapCenter = MapConfig.sanitize(_ctrl.center);
    final markers = <Marker>[
      if (_ctrl.myLocation != null)
        Marker(
          point: _ctrl.myLocation!,
          width: 22,
          height: 22,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      for (final p in places)
        if (p.point != null)
          Marker(
            point: p.point!,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showPlaceSheet(p, p.point!),
              child: Icon(
                Icons.place,
                color: _ctrl.communityMode ? const Color(0xFFE53935) : const Color(0xFF1565C0),
                size: 36,
              ),
            ),
          ),
    ];

    if (_ctrl.listView) {
      return Stack(
        children: [
          _buildListViewLayout(),
          Positioned(right: 16, bottom: 96, child: _buildFabColumn()),
        ],
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: MapConfig.defaultZoom,
            onMapReady: () => _mapReady = true,
            onTap: (_, point) {
              if (!MapConfig.isValidLatLng(point)) return;
              _showPickLocationSheet(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileUrlTemplate,
              userAgentPackageName: MapConfig.userAgentPackageName,
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildTagFilterBar(),
                if (_ctrl.locationHint != null && !_ctrl.locating)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _HintBanner(message: _ctrl.locationHint!),
                  ),
              ],
            ),
          ),
        ),
        if (_ctrl.loadingPlaces)
          const Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Center(child: CircularProgressIndicator()),
          ),
        Positioned(right: 16, bottom: 96, child: _buildFabColumn()),
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
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
