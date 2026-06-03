import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/place_model.dart';
import '../../../study_near_me/presentation/controllers/study_near_me_controller.dart';
import '../../../study_near_me/presentation/widgets/study_near_me_button.dart';
import '../../../study_near_me/presentation/widgets/study_near_me_results_sheet.dart';
import '../controllers/places_map_controller.dart';
import '../places_map_focus.dart';
import '../widgets/place_list_tile.dart';
import '../widgets/place_tag_chips.dart';
import '../widgets/places_header_panel.dart';
import '../widgets/places_map_loading_skeleton.dart';
import '../widgets/places_map_zoom_controls.dart';

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
  late final StudyNearMeController _studyNearMeCtrl;
  Timer? _searchDebounce;
  bool _mapReady = false;
  bool _placeSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _ctrl = PlacesMapController();
    _studyNearMeCtrl = StudyNearMeController();
    _ctrl.addListener(_onControllerUpdate);
    _studyNearMeCtrl.addListener(_onControllerUpdate);
    PlacesMapFocus.pending.addListener(_onPendingMapFocus);
    PlacesMapFocus.highlightedPlaceId.addListener(_onControllerUpdate);
    _ctrl.init();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _onPendingMapFocus() {
    final req = PlacesMapFocus.pending.value;
    if (req == null || !mounted) return;
    PlacesMapFocus.pending.value = null;
    _applyMapFocus(req);
  }

  void _applyMapFocus(PlacesMapFocusRequest req) {
    PlacesMapFocus.highlight(req.placeId);

    PlaceModel? matched;
    for (final place in [..._ctrl.publicPlaces, ..._ctrl.myPlaces]) {
      if (place.id == req.placeId) {
        matched = place;
        break;
      }
    }

    if (matched != null && matched.point != null) {
      _focusPlaceOnMap(matched);
      return;
    }

    final point = LatLng(req.lat, req.lng);
    _ctrl.setListView(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _safeMove(point, 15);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _ctrl.removeListener(_onControllerUpdate);
    _studyNearMeCtrl.removeListener(_onControllerUpdate);
    PlacesMapFocus.pending.removeListener(_onPendingMapFocus);
    PlacesMapFocus.highlightedPlaceId.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    _studyNearMeCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    try {
      final camera = _mapController.camera;
      final newZoom = (camera.zoom + delta).clamp(3.0, 18.0);
      _mapController.move(camera.center, newZoom);
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _ctrl.setSearchQuery(value);
      _ctrl.loadPlaces();
    });
  }

  PlaceModel? _placeFromMarker(Marker marker) {
    final key = marker.key;
    if (key is! ValueKey<String>) return null;
    final id = key.value;
    for (final place in _ctrl.activePlaces) {
      if (place.id == id) return place;
    }
    return null;
  }

  List<Marker> _buildPlaceMarkers(List<PlaceModel> places) {
    final pinColor = _ctrl.communityMode ? const Color(0xFFE53935) : const Color(0xFF1565C0);
    final highlightedId = PlacesMapFocus.highlightedPlaceId.value;

    final normal = <Marker>[];
    Marker? highlighted;

    for (final p in places) {
      if (p.point == null) continue;
      final isHighlighted = p.id == highlightedId;
      final marker = Marker(
        key: ValueKey(p.id),
        point: p.point!,
        width: isHighlighted ? 56 : 40,
        height: isHighlighted ? 56 : 40,
        alignment: Alignment.bottomCenter,
        child: _buildPlaceMarkerIcon(
          isHighlighted: isHighlighted,
          pinColor: pinColor,
        ),
      );
      if (isHighlighted) {
        highlighted = marker;
      } else {
        normal.add(marker);
      }
    }

    if (highlighted != null) return [...normal, highlighted];
    return normal;
  }

  Widget _buildPlaceMarkerIcon({
    required bool isHighlighted,
    required Color pinColor,
  }) {
    if (!isHighlighted) {
      return Icon(Icons.place_rounded, color: pinColor, size: 36);
    }

    const highlightColor = Color(0xFFFF6F00);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: highlightColor.withValues(alpha: 0.22),
            shape: BoxShape.circle,
            border: Border.all(color: highlightColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: highlightColor.withValues(alpha: 0.45),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const Icon(Icons.place, color: highlightColor, size: 44),
      ],
    );
  }

  void _safeMove(LatLng target, double zoom) {
    if (!MapConfig.isValidLatLng(target) || !_mapReady) return;
    try {
      _mapController.move(target, zoom);
    } catch (_) {}
  }

  PlaceModel? _findPlaceById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final place in [..._ctrl.publicPlaces, ..._ctrl.myPlaces]) {
      if (place.id == id) return place;
    }
    return null;
  }

  void _clearPlaceSelection({bool closeSheet = true}) {
    PlacesMapFocus.clearHighlight();
    if (closeSheet && _placeSheetOpen && mounted) {
      Navigator.pop(context);
    }
  }

  void _focusPlaceOnMap(PlaceModel place) {
    final point = place.point;
    if (point == null) return;
    PlacesMapFocus.highlight(place.id);
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
              const SizedBox(height: 6),
              Text(
                'Mẹo: nhấn giữ bản đồ để chọn vị trí, hoặc dùng nút +',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
    PlacesMapFocus.highlight(place.id);
    final distanceText = _ctrl.distanceLabelFor(place);

    _placeSheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.title,
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearPlaceSelection(closeSheet: false);
                        },
                        icon: const Icon(Icons.close),
                        tooltip: 'Bỏ chọn địa điểm',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (place.address != null && place.address!.isNotEmpty)
                    Text(
                      place.address!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  const SizedBox(height: 8),
                  PlaceTagDisplay(tagIds: place.tags),
                  if (place.body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      place.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Khoảng cách: $distanceText',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _clearPlaceSelection(closeSheet: false);
                    },
                    icon: const Icon(Icons.place_outlined),
                    label: const Text('Bỏ chọn địa điểm'),
                  ),
                  const SizedBox(height: 8),
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
                      label: const Text(
                        'Xóa địa điểm',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _placeSheetOpen = false;
    });
  }

  Widget _buildHighlightBanner() {
    final highlightedId = PlacesMapFocus.highlightedPlaceId.value;
    if (highlightedId == null) return const SizedBox.shrink();

    final place = _findPlaceById(highlightedId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        child: InkWell(
          onTap: _clearPlaceSelection,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.place, color: Color(0xFFFF6F00), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    place?.title ?? 'Địa điểm đang chọn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _clearPlaceSelection,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Bỏ chọn'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
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
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    setState(() {});
                  },
                )
              : null,
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
        onChanged: (value) {
          setState(() {});
          _onSearchChanged(value);
        },
        onSubmitted: _onSearchChanged,
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

  Future<void> _onStudyNearMe() async {
    final ok = await _studyNearMeCtrl.loadNearby(location: _ctrl.myLocation);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_studyNearMeCtrl.error ?? 'Không tìm được kết quả')),
      );
      return;
    }
    final result = _studyNearMeCtrl.result;
    if (result != null) {
      await StudyNearMeResultsSheet.show(
        context,
        result: result,
        onRetry: _onStudyNearMe,
      );
    }
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
      return PlacesMapLoadingSkeleton(listMode: listMode);
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
                    ? 'Thêm địa điểm đầu tiên bằng nút + trên bản đồ.'
                    : 'Nhấn giữ bản đồ hoặc nút + để thêm địa điểm.',
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
          mapPoint: place.point,
          showMiniMap: listMode && place.point != null,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StudyNearMeButton(
                      compact: true,
                      loading: _studyNearMeCtrl.loading,
                      onPressed: _onStudyNearMe,
                    ),
                  ),
                ),
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

  Widget _buildMapLayout(List<PlaceModel> places) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mapCenter = MapConfig.sanitize(_ctrl.center);
    final placeMarkers = _buildPlaceMarkers(places);
    final primary = theme.colorScheme.primary;

    return Stack(
      key: const ValueKey('map_view'),
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: MapConfig.defaultZoom,
            onMapReady: () => _mapReady = true,
            onTap: (_, __) => _clearPlaceSelection(),
            onLongPress: (_, point) {
              if (!MapConfig.isValidLatLng(point)) return;
              _showPickLocationSheet(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileUrlTemplate,
              userAgentPackageName: MapConfig.userAgentPackageName,
            ),
            if (_ctrl.myLocation != null)
              MarkerLayer(
                markers: [
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
                ],
              ),
            if (placeMarkers.isNotEmpty)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 50,
                  size: const Size(44, 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 16,
                  zoomToBoundsOnClick: true,
                  markers: placeMarkers,
                  onMarkerTap: (marker) {
                    final place = _placeFromMarker(marker);
                    if (place?.point == null) return;
                    if (PlacesMapFocus.highlightedPlaceId.value == place!.id) {
                      _clearPlaceSelection();
                      return;
                    }
                    PlacesMapFocus.highlight(place.id);
                    _safeMove(place.point!, 15);
                    _showPlaceSheet(place, place.point!);
                  },
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StudyNearMeButton(
                      compact: true,
                      loading: _studyNearMeCtrl.loading,
                      onPressed: _onStudyNearMe,
                    ),
                  ),
                ),
                _buildTagFilterBar(),
                _buildHighlightBanner(),
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
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            bottom: 0,
            child: const PlacesMapLoadingSkeleton(),
          ),
        Positioned(
          left: 16,
          bottom: 96,
          child: PlacesMapZoomControls(
            onZoomIn: () => _zoomBy(1),
            onZoomOut: () => _zoomBy(-1),
          ),
        ),
        Positioned(right: 16, bottom: 96, child: _buildFabColumn()),
        Positioned(
          left: 12,
          bottom: 168,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF242424) : Colors.white).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBody(List<PlaceModel> places) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final isList = child.key == const ValueKey('list_view');
        final slide = Tween<Offset>(
          begin: Offset(0, isList ? 0.04 : -0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: _ctrl.listView
          ? KeyedSubtree(
              key: const ValueKey('list_view'),
              child: _buildListViewLayout(),
            )
          : _buildMapLayout(places),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = _ctrl.activePlaces;
    return _buildAnimatedBody(places);
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
