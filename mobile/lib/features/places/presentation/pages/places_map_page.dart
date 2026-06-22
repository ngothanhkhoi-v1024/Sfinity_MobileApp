import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_config.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/place_model.dart';
import '../../../study_near_me/presentation/controllers/study_near_me_controller.dart';
import '../../../study_near_me/presentation/widgets/study_near_me_results_sheet.dart';
import '../controllers/places_map_controller.dart';
import '../places_map_focus.dart';
import '../widgets/animated_place_map_pin.dart';
import '../widgets/place_list_tile.dart';
import '../widgets/place_map_pin.dart';
import '../widgets/place_tag_chips.dart';
import '../widgets/places_map_loading_skeleton.dart';
import '../widgets/places_map_toolbar.dart';
import '../widgets/places_map_zoom_controls.dart';

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
  Timer? _filterDebounce;
  bool _mapReady = false;
  bool _placeSheetOpen = false;
  Set<String> _favoritePlaceIds = {};
  bool _wasLoadingPlaces = true;

  @override
  void initState() {
    super.initState();
    _ctrl = PlacesMapController();
    _studyNearMeCtrl = StudyNearMeController();
    _ctrl.addListener(_onControllerUpdate);
    _studyNearMeCtrl.addListener(_onControllerUpdate);
    PlacesMapFocus.pending.addListener(_onPendingMapFocus);
    PlacesMapFocus.highlightedPlaceId.addListener(_onControllerUpdate);
    PlacesMapFocus.pulseHighlight.addListener(_onControllerUpdate);
    _ctrl.init();
    _loadFavoritePlaces();
  }

  Future<void> _loadFavoritePlaces() async {
    try {
      final favs = await ApiClient.instance.getList('/favorites');
      final ids = <String>{};
      for (final raw in favs) {
        final fav = raw as Map<String, dynamic>;
        final doc = fav['document'] as Map<String, dynamic>?;
        if (doc == null) continue;
        final isPlace = doc['type']?.toString() == 'place' ||
            (doc['body']?.toString() ?? '').contains('type:place');
        if (!isPlace) continue;
        final id = doc['id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      }
      if (mounted) setState(() => _favoritePlaceIds = ids);
    } catch (_) {}
  }

  bool _isSavedPlace(PlaceModel place) =>
      !_ctrl.communityMode || _favoritePlaceIds.contains(place.id);

  PlaceMapPinVariant _pinVariant(PlaceModel place, {required bool isHighlighted}) {
    final savedStyle = _isSavedPlace(place);
    if (isHighlighted) {
      return savedStyle
          ? PlaceMapPinVariant.highlightedSaved
          : PlaceMapPinVariant.highlightedCommunity;
    }
    return savedStyle ? PlaceMapPinVariant.saved : PlaceMapPinVariant.community;
  }

  void _onControllerUpdate() {
    if (!_ctrl.loadingPlaces && _wasLoadingPlaces) {
      _wasLoadingPlaces = false;
      _loadFavoritePlaces();
    } else if (_ctrl.loadingPlaces) {
      _wasLoadingPlaces = true;
    }
    if (mounted) setState(() {});
  }

  void _onPendingMapFocus() {
    final req = PlacesMapFocus.pending.value;
    if (req == null || !mounted) return;
    PlacesMapFocus.pending.value = null;
    _applyMapFocus(req);
  }

  void _applyMapFocus(PlacesMapFocusRequest req) {
    PlacesMapFocus.highlight(
      req.placeId,
      focusSource: req.source,
      pulse: req.pulse,
    );

    final matched = req.place ?? _findPlaceById(req.placeId);

    if (matched != null && matched.point != null) {
      _focusPlaceOnMap(
        matched,
        openSheet: req.openSheet,
        zoom: req.zoom,
      );
      return;
    }

    _ctrl.setMapFocusPlace(null);
    final point = LatLng(req.lat, req.lng);
    _ctrl.setListView(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _safeMove(point, req.zoom);
    });
  }

  void _scheduleFilterReload() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      _ctrl.setSearchQuery(_searchController.text);
      await _ctrl.loadPlaces();
      if (!mounted) return;
      final id = PlacesMapFocus.highlightedPlaceId.value;
      if (id == null) return;
      final place = _findPlaceById(id) ?? _ctrl.mapFocusPlace;
      if (place != null) _ctrl.setMapFocusPlace(place);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _filterDebounce?.cancel();
    _ctrl.removeListener(_onControllerUpdate);
    _studyNearMeCtrl.removeListener(_onControllerUpdate);
    PlacesMapFocus.pending.removeListener(_onPendingMapFocus);
    PlacesMapFocus.highlightedPlaceId.removeListener(_onControllerUpdate);
    PlacesMapFocus.pulseHighlight.removeListener(_onControllerUpdate);
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
    final highlightedId = PlacesMapFocus.highlightedPlaceId.value;
    final shouldPulse = PlacesMapFocus.pulseHighlight.value;

    final normal = <Marker>[];
    Marker? highlighted;

    for (final p in places) {
      if (p.point == null) continue;
      final isHighlighted = p.id == highlightedId;
      final pinSize = isHighlighted ? 56.0 : 40.0;
      final marker = Marker(
        key: ValueKey(p.id),
        point: p.point!,
        width: pinSize,
        height: pinSize,
        alignment: Alignment.bottomCenter,
        child: AnimatedPlaceMapPin(
          variant: _pinVariant(p, isHighlighted: isHighlighted),
          size: pinSize,
          pulse: isHighlighted && shouldPulse,
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
    _ctrl.clearMapFocusPlace();
    if (closeSheet && _placeSheetOpen && mounted) {
      Navigator.pop(context);
    }
  }

  void _focusPlaceOnMap(
    PlaceModel place, {
    bool openSheet = true,
    double zoom = 15,
  }) {
    final point = place.point;
    if (point == null) return;
    _ctrl.setMapFocusPlace(place);
    PlacesMapFocus.highlight(
      place.id,
      focusSource: PlacesMapFocus.source.value ?? PlacesMapFocusSource.map,
      pulse: PlacesMapFocus.pulseHighlight.value,
    );
    _ctrl.setListView(false);
    _safeMove(point, zoom);
    if (openSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showPlaceSheet(place, point);
      });
    }
  }

  Future<void> _deletePlace(String placeId) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePlace),
        content: Text(l10n.deletePlaceConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancelBtn2)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _ctrl.deletePlace(placeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.placeDeleted)),
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
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(l10n.saveNewPlace, style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.holdMapOrButton,
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
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: Text(l10n.saveThisPlace),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPlaceSheet(PlaceModel place, LatLng point) {
    final l10n = context.l10n;
    _ctrl.setMapFocusPlace(place);
    PlacesMapFocus.highlight(
      place.id,
      focusSource: PlacesMapFocus.source.value ?? PlacesMapFocusSource.map,
      pulse: PlacesMapFocus.pulseHighlight.value,
    );
    final distanceText = _ctrl.distanceLabelFor(place, noLocationYet: () => l10n.noYourLocation);

    _placeSheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final l10n = ctx.l10n;
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final primary = theme.colorScheme.primary;
        final saved = _isSavedPlace(place);
        final surface = isDark ? const Color(0xFF1A1A1A) : Colors.white;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlaceMapPin(
                          variant: saved
                              ? PlaceMapPinVariant.highlightedSaved
                              : PlaceMapPinVariant.highlightedCommunity,
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  distanceText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _clearPlaceSelection(closeSheet: false);
                          },
                          icon: const Icon(Icons.close_rounded),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (place.address != null && place.address!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              place.address!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (place.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      PlaceTagDisplay(tagIds: place.tags),
                    ],
                    if (place.body.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        place.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _PlaceSheetAction(
                      icon: Icons.visibility_rounded,
                      label: l10n.viewPlaceDetail,
                      primary: true,
                      onTap: place.id.isEmpty
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              context.push('/places/${place.id}');
                            },
                    ),
                    _PlaceSheetAction(
                      icon: Icons.deselect_rounded,
                      label: l10n.remove,
                      onTap: () {
                        Navigator.pop(ctx);
                        _clearPlaceSelection(closeSheet: false);
                      },
                    ),
                    if (_ctrl.isOwnedByCurrentUser(place) && place.id.isNotEmpty) ...[
                      _PlaceSheetAction(
                        icon: Icons.upload_file_rounded,
                        label: l10n.searchDocument,
                        onTap: () {
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
                      ),
                      _PlaceSheetAction(
                        icon: Icons.edit_rounded,
                        label: l10n.editPlace,
                        onTap: () {
                          Navigator.pop(ctx);
                          context.push('/places/${place.id}/edit').then((_) => _ctrl.loadPlaces());
                        },
                      ),
                      _PlaceSheetAction(
                        icon: Icons.delete_outline_rounded,
                        label: l10n.deletePlace,
                        destructive: true,
                        onTap: () {
                          Navigator.pop(ctx);
                          _deletePlace(place.id);
                        },
                      ),
                    ],
                  ],
                ),
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
    final l10n = context.l10n;
    final highlightedId = PlacesMapFocus.highlightedPlaceId.value;
    if (highlightedId == null || _placeSheetOpen) return const SizedBox.shrink();

    final place = _findPlaceById(highlightedId) ?? _ctrl.mapFocusPlace;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final saved = place != null && _isSavedPlace(place);
    final hiddenByFilter =
        place != null && !_ctrl.isPlaceInCurrentResults(place.id);
    final muted = theme.brightness == Brightness.dark
        ? Colors.grey.shade400
        : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Material(
        color: PlaceMapPin.selectedColor.withValues(alpha: 0.12),
        elevation: 0,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: place != null
              ? () {
                  final p = place.point;
                  if (p != null) _showPlaceSheet(place, p);
                }
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: PlaceMapPin.selectedColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                AnimatedPlaceMapPin(
                  variant: saved
                      ? PlaceMapPinVariant.highlightedSaved
                      : PlaceMapPinVariant.highlightedCommunity,
                  size: 28,
                  pulse: PlacesMapFocus.pulseHighlight.value,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        place?.title ?? l10n.selectedLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (hiddenByFilter)
                        GestureDetector(
                          onTap: () {
                            _ctrl.setFilterTags({});
                            _searchController.clear();
                            _ctrl.setSearchQuery('');
                            _scheduleFilterReload();
                          },
                          child: Text(
                            '${l10n.placeHiddenByFilters} · ${l10n.showAllPlaces}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: muted),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _clearPlaceSelection,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: primary,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: l10n.clearMapSelection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToDetailButton() {
    if (PlacesMapFocus.source.value != PlacesMapFocusSource.detail) {
      return const SizedBox.shrink();
    }
    final placeId = PlacesMapFocus.highlightedPlaceId.value;
    if (placeId == null || placeId.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF242424) : Colors.white;

    return Positioned(
      left: 16,
      bottom: 188,
      child: Material(
        color: surface.withValues(alpha: 0.96),
        elevation: 3,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            PlacesMapFocus.clearHighlight();
            context.push('/places/$placeId');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.backToPlaceDetail,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar({required bool mapOverlay}) {
    return PlacesMapToolbar(
      mapOverlay: mapOverlay,
      communityMode: _ctrl.communityMode,
      listView: _ctrl.listView,
      onCommunityChanged: _ctrl.setCommunityMode,
      onViewChanged: _ctrl.setListView,
      searchController: _searchController,
      onSearchChanged: (value) {
        setState(() {});
        _onSearchChanged(value);
      },
      filterTags: _ctrl.filterTags,
      filterCount: _ctrl.activeFilterCount,
      minRating: _ctrl.minRating,
      onFilterChanged: (tags) {
        _ctrl.setFilterTags(tags);
        _scheduleFilterReload();
      },
      onMinRatingChanged: (rating) {
        _ctrl.setMinRating(rating);
        _scheduleFilterReload();
      },
      studyNearMeLoading: _studyNearMeCtrl.loading,
      onStudyNearMe: _onStudyNearMe,
      highlightBanner: mapOverlay && PlacesMapFocus.highlightedPlaceId.value != null
          ? _buildHighlightBanner()
          : null,
      locationHint: _ctrl.locationHint != null && !_ctrl.locating ? _ctrl.locationHint : null,
    );
  }

  Future<void> _onStudyNearMe() async {
    final l10n = context.l10n;
    final ok = await _studyNearMeCtrl.loadNearby(location: _ctrl.myLocation);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_studyNearMeCtrl.error ?? l10n.noResultsFound)),
      );
      return;
    }
    final result = _studyNearMeCtrl.result;
    if (result != null) {
      await StudyNearMeResultsSheet.show(
        context,
        controller: _studyNearMeCtrl,
        onRefresh: () => _studyNearMeCtrl.loadNearby(location: _ctrl.myLocation),
      );
    }
  }

  Widget _buildListSectionHeader(int count) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ctrl.communityMode ? l10n.communityPlaces : l10n.myPlaces,
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
                    l10n.nearby,
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
    final l10n = context.l10n;
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
                _ctrl.communityMode ? l10n.noPlaceCommunity : l10n.noPlace,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _ctrl.communityMode ? l10n.addFirstPlace : l10n.holdMapOrButton,
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
          distanceLabel: _ctrl.distanceLabelFor(place, noLocationYet: () => context.l10n.noYourLocation),
          isCommunity: _ctrl.communityMode,
          isSaved: _isSavedPlace(place),
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
            child: _buildToolbar(mapOverlay: false),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final border = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB);
    final primary = Theme.of(context).colorScheme.primary;

    Widget fab({
      required String heroTag,
      required IconData icon,
      required VoidCallback? onPressed,
      bool primaryStyle = false,
    }) {
      return Material(
        color: primaryStyle ? primary : bg,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black26,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: primaryStyle ? null : Border.all(color: border),
            ),
            child: Icon(
              icon,
              size: 22,
              color: primaryStyle ? Colors.white : (isDark ? Colors.white : primary),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        fab(
          heroTag: 'refresh_places',
          icon: Icons.refresh_rounded,
          onPressed: () async {
            _ctrl.setSearchQuery(_searchController.text);
            await _ctrl.loadPlaces();
            await _loadFavoritePlaces();
          },
        ),
        const SizedBox(height: 8),
        fab(
          heroTag: 'add_place',
          icon: Icons.add_location_alt_rounded,
          onPressed: () => context.push(RouteNames.placeShare).then((_) => _ctrl.loadPlaces()),
          primaryStyle: true,
        ),
        const SizedBox(height: 8),
        fab(
          heroTag: 'my_location',
          icon: Icons.my_location_rounded,
          onPressed: _ctrl.locating
              ? null
              : () async {
                  await _ctrl.initLocation(
        enableGPSHint: () => context.l10n.enableGPSNearMe,
        cannotGetLocation: () => context.l10n.cannotGetCurrentLocation,
      );
                  final here = _ctrl.myLocation;
                  if (here != null) _safeMove(here, 14);
                },
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
                    PlacesMapFocus.highlight(
                      place.id,
                      focusSource: PlacesMapFocusSource.map,
                      pulse: false,
                    );
                    _ctrl.setMapFocusPlace(place);
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
            child: _buildToolbar(mapOverlay: true),
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
        _buildBackToDetailButton(),
        Positioned(
          left: 16,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF242424) : Colors.white).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
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
    final places = _ctrl.placesForMap;
    return _buildAnimatedBody(places);
  }
}

class _PlaceSheetAction extends StatelessWidget {
  const _PlaceSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (primary) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    final fg = destructive ? Colors.red.shade600 : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF252525)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: destructive ? Colors.red.shade600 : colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
