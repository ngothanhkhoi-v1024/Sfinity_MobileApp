import 'package:flutter/foundation.dart';

import '../data/models/place_model.dart';

/// Nguồn yêu cầu focus — ảnh hưởng UI (banner, sheet, zoom).
enum PlacesMapFocusSource {
  detail,
  map,
  list,
}

class PlacesMapFocusRequest {
  const PlacesMapFocusRequest({
    required this.placeId,
    required this.lat,
    required this.lng,
    this.place,
    this.openSheet = false,
    this.zoom = 15,
    this.source = PlacesMapFocusSource.map,
    this.pulse = false,
  });

  final String placeId;
  final double lat;
  final double lng;

  /// Địa điểm đầy đủ khi chưa có trong danh sách đã lọc.
  final PlaceModel? place;
  final bool openSheet;
  final double zoom;
  final PlacesMapFocusSource source;

  /// Bật hiệu ứng pulse trên pin (thường từ chi tiết).
  final bool pulse;
}

/// Điều hướng / highlight địa điểm trên tab bản đồ.
abstract final class PlacesMapFocus {
  static final pending = ValueNotifier<PlacesMapFocusRequest?>(null);

  static final highlightedPlaceId = ValueNotifier<String?>(null);

  static final source = ValueNotifier<PlacesMapFocusSource?>(null);

  static final pulseHighlight = ValueNotifier<bool>(false);

  static void request({
    required String placeId,
    required double lat,
    required double lng,
    PlaceModel? place,
    bool openSheet = false,
    double zoom = 15,
    PlacesMapFocusSource focusSource = PlacesMapFocusSource.detail,
    bool pulse = true,
  }) {
    highlightedPlaceId.value = placeId;
    source.value = focusSource;
    pulseHighlight.value = pulse && focusSource == PlacesMapFocusSource.detail;
    pending.value = PlacesMapFocusRequest(
      placeId: placeId,
      lat: lat,
      lng: lng,
      place: place,
      openSheet: openSheet,
      zoom: zoom,
      source: focusSource,
      pulse: pulse,
    );
  }

  static void highlight(
    String placeId, {
    PlacesMapFocusSource focusSource = PlacesMapFocusSource.map,
    bool pulse = false,
  }) {
    highlightedPlaceId.value = placeId;
    source.value = focusSource;
    pulseHighlight.value = pulse;
  }

  static void clearHighlight() {
    highlightedPlaceId.value = null;
    source.value = null;
    pulseHighlight.value = false;
  }
}
