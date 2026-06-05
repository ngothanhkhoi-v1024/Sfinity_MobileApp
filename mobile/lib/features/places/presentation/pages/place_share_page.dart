import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/place_location_service.dart';
import '../controllers/place_form_controller.dart';
import '../widgets/place_cover_image_picker.dart';
import '../widgets/place_tag_chips.dart';
import '../widgets/places_map_zoom_controls.dart';

class PlaceSharePage extends StatefulWidget {
  const PlaceSharePage({super.key, this.editPlaceId});

  final String? editPlaceId;

  @override
  State<PlaceSharePage> createState() => _PlaceSharePageState();
}

class _PlaceSharePageState extends State<PlaceSharePage> {
  final _mapController = MapController();
  final _locationService = PlaceLocationService();
  late final PlaceFormController _ctrl;
  bool _pickedFromRoute = false;
  bool _mapReady = false;
  bool _locating = false;
  bool _autoLocated = false;

  bool get _isEdit => widget.editPlaceId != null && widget.editPlaceId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ctrl = PlaceFormController();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    if (_isEdit) {
      _ctrl.loadForEdit(widget.editPlaceId!).then((_) {
        if (mounted && _mapReady) _moveMapTo(_ctrl.picked, 15);
      }).catchError((e) {
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _moveMapTo(_ctrl.picked, 16);
        });
        return;
      }
    }
    if (!_autoLocated) {
      _autoLocated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToCurrentLocation(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _moveMapTo(LatLng point, double zoom) {
    if (!_mapReady || !MapConfig.isValidLatLng(point)) return;
    try {
      _mapController.move(point, zoom);
    } catch (_) {}
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    try {
      final camera = _mapController.camera;
      final newZoom = (camera.zoom + delta).clamp(3.0, 18.0);
      _mapController.move(camera.center, newZoom);
    } catch (_) {}
  }

  Future<void> _goToCurrentLocation({bool silent = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    final l10n = context.l10n;
    try {
      final point = await _locationService.getCurrentLocation();
      if (!mounted) return;
      if (point == null) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.cannotGetCurrentLocation)),
          );
        }
        return;
      }
      _ctrl.onMapTap(point);
      _moveMapTo(point, 16);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMapTap(LatLng point) {
    _ctrl.onMapTap(point);
    _moveMapTo(point, _mapReady ? _mapController.camera.zoom : 15);
  }

  void _selectSearchResult(GeocodingResult result) {
    _ctrl.selectSearchResult(result);
    _moveMapTo(_ctrl.picked, 16);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    try {
      await _ctrl.submit(
        editPlaceId: widget.editPlaceId,
        nameRequired: () => l10n.placeNameRequired,
        invalidCoordinates: () => l10n.invalidCoordinates,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? l10n.updatePlace : l10n.savedPlace)),
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
    final l10n = context.l10n;
    if (_ctrl.loadingPlace) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? l10n.editPlace : l10n.saveNewPlace)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final picked = MapConfig.sanitize(_ctrl.picked);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editPlace : l10n.saveNewPlace)),
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
                      hintText: l10n.searchPlaceByName,
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
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: picked,
                    initialZoom: 15,
                    onMapReady: () {
                      _mapReady = true;
                      _moveMapTo(_ctrl.picked, _isEdit ? 15 : 16);
                    },
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
                          child: const Icon(
                            Icons.place,
                            color: Color(0xFFE53935),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: PlacesMapZoomControls(
                    onZoomIn: () => _zoomBy(1),
                    onZoomOut: () => _zoomBy(-1),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Tooltip(
                    message: l10n.groupMapCenterMe,
                    child: Material(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF242424)
                          : Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black26,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _locating ? null : () => _goToCurrentLocation(),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: _locating
                              ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryOf(context),
                                  ),
                                )
                              : Icon(
                                  Icons.my_location_rounded,
                                  size: 22,
                                  color: AppColors.primaryOf(context),
                                ),
                        ),
                      ),
                    ),
                  ),
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
                  Text(l10n.loading, style: const TextStyle(fontSize: 12))
                else if (_ctrl.address != null && _ctrl.address!.isNotEmpty)
                  Text(
                    _ctrl.address!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  )
                else
                  Text(
                    '${l10n.placePickLocationHint} · ${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}',
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
                    decoration: InputDecoration(
                      labelText: l10n.placeName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PlaceCoverImagePicker(
                    pickedFile: _ctrl.pickedCoverImage,
                    previewUrl: _ctrl.coverPreviewUrl,
                    enabled: !_ctrl.loading,
                    onPick: () async {
                      final file = await pickPlaceCoverImage(context);
                      if (file != null) _ctrl.setPickedCover(file);
                    },
                    onClear: _ctrl.clearCover,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl.descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.additionalDescription,
                      border: const OutlineInputBorder(),
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
                      l10n.placeDisplayOnMap,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text(l10n.personal),
                        icon: const Icon(Icons.lock_outline, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text(l10n.communityContent),
                        icon: const Icon(Icons.public, size: 18),
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
                        ? l10n.placeWillShowMap
                        : l10n.noPlaceCommunity,
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
                          ? l10n.loading
                          : (_isEdit ? l10n.updatePlace : l10n.savePlace),
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
