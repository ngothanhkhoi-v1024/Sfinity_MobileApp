import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';
import '../../../friendships/data/models/friend_model.dart';
import '../../../places/data/services/place_location_service.dart';
import '../../data/services/group_api_service.dart';

class GroupMembersMapTab extends StatefulWidget {
  const GroupMembersMapTab({
    super.key,
    required this.groupId,
    required this.myUserId,
    required this.tabController,
    required this.mapTabIndex,
  });

  final String groupId;
  final String myUserId;
  final TabController tabController;
  final int mapTabIndex;

  @override
  State<GroupMembersMapTab> createState() => _GroupMembersMapTabState();
}

class _GroupMembersMapTabState extends State<GroupMembersMapTab> {
  final _mapController = MapController();
  final _locationService = PlaceLocationService();
  late final GroupApiService _api;

  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;
  bool _sharing = false;
  bool _locationDenied = false;
  String? _error;
  Timer? _pollTimer;
  Timer? _shareTimer;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _api = GroupApiService(ApiClient.instance);
    widget.tabController.addListener(_onTabChanged);
    if (widget.tabController.index == widget.mapTabIndex) {
      _activateMap();
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    _pollTimer?.cancel();
    _shareTimer?.cancel();
    _stopSharing(silent: true);
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (widget.tabController.index == widget.mapTabIndex) {
      _activateMap();
    } else {
      _deactivateMap();
    }
  }

  Future<void> _activateMap() async {
    await _loadLocations();
    await _startSharing();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadLocations());
  }

  Future<void> _deactivateMap() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _shareTimer?.cancel();
    _shareTimer = null;
    await _stopSharing(silent: true);
    if (mounted) setState(() => _sharing = false);
  }

  Future<void> _loadLocations() async {
    if (!mounted) return;
    setState(() {
      _loading = _locations.isEmpty;
      _error = null;
    });
    try {
      final items = await _api.getMemberLocations(widget.groupId);
      if (!mounted) return;
      setState(() {
        _locations = items;
        _loading = false;
      });
      _fitMapToMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _startSharing() async {
    final reading = await _locationService.getCurrentLocationReading();
    if (!mounted) return;

    if (reading == null) {
      setState(() {
        _locationDenied = true;
        _sharing = false;
      });
      return;
    }

    setState(() {
      _locationDenied = false;
      _sharing = true;
    });

    await _pushLocation(reading.point, reading.accuracyM);
    _shareTimer?.cancel();
    _shareTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final latest = await _locationService.getCurrentLocationReading();
      if (latest != null) {
        await _pushLocation(latest.point, latest.accuracyM);
      }
    });
  }

  Future<void> _pushLocation(LatLng point, double accuracy) async {
    try {
      await _api.updateMyLocation(
        widget.groupId,
        latitude: point.latitude,
        longitude: point.longitude,
        accuracy: accuracy,
      );
      if (!mounted) return;
      await _loadLocations();
    } catch (_) {}
  }

  Future<void> _stopSharing({bool silent = false}) async {
    try {
      await _api.clearMyLocation(widget.groupId);
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.error)),
        );
      }
    }
  }

  void _fitMapToMarkers() {
    if (!_mapReady || _locations.isEmpty) return;

    final points = _locations
        .map((item) => MapConfig.latLngFromCoords(
              (item['latitude'] as num).toDouble(),
              (item['longitude'] as num).toDouble(),
            ))
        .whereType<LatLng>()
        .toList();

    if (points.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (points.length == 1) {
        _mapController.move(points.first, 15);
        return;
      }
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(56),
        ),
      );
    });
  }

  Future<void> _centerOnMe() async {
    final reading = await _locationService.getCurrentLocationReading();
    if (!mounted) return;
    if (reading == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupMapLocationDenied)),
      );
      return;
    }
    _mapController.move(reading.point, 16);
    await _pushLocation(reading.point, reading.accuracyM);
  }

  void _openProfile(Map<String, dynamic> item) {
    final userId = item['userId']?.toString() ?? '';
    if (userId.isEmpty || userId == widget.myUserId) return;
    context.push(
      RouteNames.viewProfile,
      extra: FriendUser(
        id: userId,
        name: item['name']?.toString() ?? '',
        avatar: item['avatar']?.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadLocations, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    final markers = _buildMarkers(context);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: MapConfig.defaultCenter,
            initialZoom: MapConfig.defaultZoom,
            onMapReady: () {
              _mapReady = true;
              _fitMapToMarkers();
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
        if (_locations.isEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : cs.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_outlined, size: 36, color: cs.primary.withValues(alpha: 0.7)),
                  const SizedBox(height: 10),
                  Text(
                    l10n.groupMapEmpty,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _locationDenied ? l10n.groupMapLocationDenied : l10n.groupMapEmptyHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _MapStatusBar(
            sharing: _sharing,
            count: _locations.length,
            locationDenied: _locationDenied,
          ),
        ),
        Positioned(
          right: 12,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'group_map_center_${widget.groupId}',
            onPressed: _centerOnMe,
            tooltip: l10n.groupMapCenterMe,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _locations.map((item) {
      final lat = (item['latitude'] as num?)?.toDouble();
      final lng = (item['longitude'] as num?)?.toDouble();
      final point = lat != null && lng != null
          ? MapConfig.latLngFromCoords(lat, lng)
          : null;
      if (point == null) return null;

      final userId = item['userId']?.toString() ?? '';
      final name = item['name']?.toString() ?? '';
      final avatar = item['avatar']?.toString();
      final isMe = userId == widget.myUserId;

      return Marker(
        point: point,
        width: 72,
        height: 86,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () => _openProfile(item),
          child: _MemberAvatarMarker(
            name: name,
            avatarUrl: avatar,
            isMe: isMe,
            accentColor: cs.primary,
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }
}

class _MapStatusBar extends StatelessWidget {
  const _MapStatusBar({
    required this.sharing,
    required this.count,
    required this.locationDenied,
  });

  final bool sharing;
  final int count;
  final bool locationDenied;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : cs.outlineVariant.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              sharing ? Icons.location_on_rounded : Icons.location_off_outlined,
              size: 16,
              color: sharing ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                sharing
                    ? l10n.groupMapSharing
                    : (locationDenied
                        ? l10n.groupMapLocationDenied
                        : l10n.groupMapEmptyHint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : cs.onSurface,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Text(
                l10n.groupMapMembersVisible(count),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberAvatarMarker extends StatelessWidget {
  const _MemberAvatarMarker({
    required this.name,
    required this.avatarUrl,
    required this.isMe,
    required this.accentColor,
  });

  final String name;
  final String? avatarUrl;
  final bool isMe;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isMe ? 3 : 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMe ? accentColor : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: accentColor.withValues(alpha: 0.15),
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
            child: hasAvatar
                ? null
                : Text(
                    initial,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 68),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }
}
