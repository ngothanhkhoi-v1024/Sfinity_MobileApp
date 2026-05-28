import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app.dart';
import '../../../../core/constants/map_config.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../widgets/place_list_tile.dart';
import '../widgets/places_header_panel.dart';

const _nearbyRadiusKm = 50.0;

/// Bản đồ địa điểm — tile OpenStreetMap (open source).
class PlacesMapPage extends StatefulWidget {
  const PlacesMapPage({super.key});

  @override
  State<PlacesMapPage> createState() => _PlacesMapPageState();
}

class _PlacesMapPageState extends State<PlacesMapPage> {
  final _mapController = MapController();
  LatLng _center = MapConfig.defaultCenter;
  LatLng? _myLocation;
  bool _locating = false;
  bool _mapReady = false;
  bool _loadingPlaces = true;
  bool _communityMode = true;
  bool _listView = false;
  String? _locationHint;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _publicPlaces = [];
  List<Map<String, dynamic>> _myPlaces = [];

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _safeMove(LatLng target, double zoom) {
    if (!MapConfig.isValidLatLng(target) || !_mapReady) return;
    try {
      _mapController.move(target, zoom);
    } catch (_) {}
  }

  Future<LatLng?> _resolveUserLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
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
    return MapConfig.latLngFromCoords(current.latitude, current.longitude);
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
          _locationHint = 'Bật GPS/quyền vị trí để xem khoảng cách gần xa';
        });
        return;
      }
      setState(() {
        _center = here;
        _myLocation = here;
        _locating = false;
      });
      _safeMove(here, 14);
      await _loadPlaces();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationHint = 'Không lấy được vị trí hiện tại';
      });
    }
  }

  Future<void> _loadPlaces() async {
    setState(() => _loadingPlaces = true);
    try {
      final me = _myLocation;
      final search = _searchController.text.trim();
      final publicRes = await SfinityApp.documentRepository.getDocuments(
        type: 'place',
        publishedOnly: true,
        lat: me?.latitude,
        lng: me?.longitude,
        radiusKm: me != null ? _nearbyRadiusKm : null,
        search: search.isNotEmpty ? search : null,
        limit: 50,
      );
      final currentUserId = SfinityApp.auth.user?['id']?.toString();
      Map<String, dynamic> myRes = const {'items': []};
      if (currentUserId != null && currentUserId.isNotEmpty) {
        myRes = await SfinityApp.documentRepository.getDocuments(
          type: 'place',
          authorId: currentUserId,
          search: search.isNotEmpty ? search : null,
          limit: 50,
        );
      }
      if (!mounted) return;
      setState(() {
        _publicPlaces = _toPlaceList(publicRes['items'] as List? ?? []);
        _myPlaces = _toPlaceList(myRes['items'] as List? ?? []);
        _loadingPlaces = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPlaces = false;
        _locationHint = ApiClient.instance.errorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPlaces = false);
    }
  }

  List<Map<String, dynamic>> _toPlaceList(List raw) {
    final out = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final point = _extractPoint(entry);
      if (point == null) continue;
      out.add({...entry, '_point': point});
    }
    return out;
  }

  LatLng? _extractPoint(Map<String, dynamic> place) {
    final latitude = place['latitude'];
    final longitude = place['longitude'];
    if (latitude is num && longitude is num) {
      return MapConfig.latLngFromCoords(latitude.toDouble(), longitude.toDouble());
    }

    // Dữ liệu cũ: lat/lng nằm trong body dạng text.
    final body = place['body']?.toString() ?? '';
    if (body.contains('type:place')) {
      final latMatch = RegExp(r'lat:\s*([-\d.]+)').firstMatch(body);
      final lngMatch = RegExp(r'lng:\s*([-\d.]+)').firstMatch(body);
      if (latMatch != null && lngMatch != null) {
        final lat = double.tryParse(latMatch.group(1)!);
        final lng = double.tryParse(lngMatch.group(1)!);
        if (lat != null && lng != null) {
          return MapConfig.latLngFromCoords(lat, lng);
        }
      }
    }
    return null;
  }

  void _focusPlaceOnMap(Map<String, dynamic> place) {
    final point = place['_point'] as LatLng?;
    if (point == null) return;
    setState(() => _listView = false);
    _safeMove(point, 15);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showPlaceSheet(place, point);
    });
  }

  void _openPlaceDetail(Map<String, dynamic> place) {
    final placeId = place['id']?.toString() ?? '';
    if (placeId.isEmpty) return;
    context.push('/places/$placeId');
  }

  List<Map<String, dynamic>> _sortedPlaces(List<Map<String, dynamic>> places) {
    final sorted = [...places];
    sorted.sort((a, b) {
      final pa = a['_point'] as LatLng;
      final pb = b['_point'] as LatLng;
      final me = _myLocation;
      if (me == null) return 0;
      final da = Geolocator.distanceBetween(me.latitude, me.longitude, pa.latitude, pa.longitude);
      final db = Geolocator.distanceBetween(me.latitude, me.longitude, pb.latitude, pb.longitude);
      return da.compareTo(db);
    });
    return sorted;
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
                  _communityMode ? 'Địa điểm cộng đồng' : 'Địa điểm của bạn',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 0
                      ? 'Chưa có địa điểm'
                      : _myLocation != null
                          ? '$count địa điểm · trong ${_nearbyRadiusKm.toInt()} km'
                          : '$count địa điểm',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (_myLocation != null)
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

  Widget _buildPlacesList(List<Map<String, dynamic>> places, {required bool listMode}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sorted = _sortedPlaces(places);

    if (_loadingPlaces) {
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
                _communityMode ? 'Chưa có địa điểm cộng đồng' : 'Chưa có địa điểm',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _communityMode
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
        final point = place['_point'] as LatLng;
        final title = place['title']?.toString() ?? 'Địa điểm';
        return PlaceListTile(
          title: title,
          subtitle: _placeSubtitle(place, community: _communityMode),
          distanceLabel: _distanceLabel(point),
          isCommunity: _communityMode,
          onTap: () => _openPlaceDetail(place),
          showMapAction: listMode,
          onMapTap: listMode ? () => _focusPlaceOnMap(place) : null,
        );
      },
    );
  }

  Widget _buildListViewLayout(List<Map<String, dynamic>> places) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F6F8);
    final sorted = _sortedPlaces(places);

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
              ],
            ),
          ),
          if (_locationHint != null && !_locating)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _HintBanner(message: _locationHint!),
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
                  Expanded(
                    child: _buildPlacesList(places, listMode: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return PlacesHeaderPanel(
      communityMode: _communityMode,
      listView: _listView,
      onCommunityChanged: (v) => setState(() => _communityMode = v),
      onViewChanged: (v) => setState(() => _listView = v),
    );
  }

  String _placeSubtitle(Map<String, dynamic> place, {required bool community}) {
    final address = place['address']?.toString();
    if (address != null && address.isNotEmpty) {
      return address;
    }
    if (community) {
      final author = place['author'] as Map<String, dynamic>?;
      return author?['name']?.toString() ?? 'Người dùng';
    }
    return 'Địa điểm của bạn';
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
      await SfinityApp.documentRepository.deleteDocument(placeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa địa điểm')),
        );
        _loadPlaces();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    }
  }

  String _distanceLabel(LatLng point) {
    final me = _myLocation;
    if (me == null) return 'Chưa có vị trí của bạn';
    final meters = Geolocator.distanceBetween(
      me.latitude,
      me.longitude,
      point.latitude,
      point.longitude,
    );
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
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
                      .then((_) => _loadPlaces());
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

  void _showPlaceSheet(Map<String, dynamic> place, LatLng point) {
    final title = place['title']?.toString() ?? 'Địa điểm';
    final description = place['body']?.toString() ?? '';
    final address = place['address']?.toString();
    final placeId = place['id']?.toString() ?? '';
    final isMine = (place['authorId']?.toString() ?? '') ==
        (SfinityApp.auth.user?['id']?.toString() ?? '');
    final distFromApi = place['distanceMeters'];
    final distanceText = distFromApi is num
        ? (distFromApi < 1000
            ? '${distFromApi.round()} m'
            : '${(distFromApi / 1000).toStringAsFixed(1)} km')
        : _distanceLabel(point);

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
              if (address != null && address.isNotEmpty)
                Text(address, style: TextStyle(color: Colors.grey.shade700)),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(description, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Text(
                'Khoảng cách: $distanceText',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: placeId.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        context.push('/places/$placeId');
                      },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Xem chi tiết địa điểm'),
              ),
              if (isMine && placeId.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(
                      RouteNames.documentCreate,
                      extra: {
                        'contentType': 'document',
                        'placeId': placeId,
                        'placeTitle': title,
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
                    context.push('/places/$placeId/edit').then((_) => _loadPlaces());
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Sửa địa điểm'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deletePlace(placeId);
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
        onSubmitted: (_) => _loadPlaces(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = _communityMode ? _publicPlaces : _myPlaces;
    final mapCenter = MapConfig.sanitize(_center);
    final markers = <Marker>[
      if (_myLocation != null)
        Marker(
          point: _myLocation!,
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
        Marker(
          point: p['_point'] as LatLng,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showPlaceSheet(p, p['_point'] as LatLng),
            child: Icon(
              Icons.place,
              color: _communityMode ? const Color(0xFFE53935) : const Color(0xFF1565C0),
              size: 36,
            ),
          ),
        ),
    ];

    if (_listView) {
      return Stack(
        children: [
          _buildListViewLayout(places),
          Positioned(
            right: 16,
            bottom: 96,
            child: _buildFabColumn(),
          ),
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
                if (_locationHint != null && !_locating)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _HintBanner(message: _locationHint!),
                  ),
              ],
            ),
          ),
        ),
        if (_loadingPlaces)
          const Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Center(child: CircularProgressIndicator()),
          ),
        Positioned(
          right: 16,
          bottom: 96,
          child: _buildFabColumn(),
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

  Widget _buildFabColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'refresh_places',
          onPressed: _loadPlaces,
          child: const Icon(Icons.refresh),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'add_place',
          onPressed: () => context.push(RouteNames.placeShare).then((_) => _loadPlaces()),
          child: const Icon(Icons.add_location_alt_outlined),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'my_location',
          onPressed: _locating ? null : _initLocation,
          child: const Icon(Icons.my_location),
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
