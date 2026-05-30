import 'package:flutter/foundation.dart';

class PlacesMapFocusRequest {
  const PlacesMapFocusRequest({
    required this.placeId,
    required this.lat,
    required this.lng,
  });

  final String placeId;
  final double lat;
  final double lng;
}

/// Điều hướng từ chi tiết địa điểm sang tab bản đồ.
abstract final class PlacesMapFocus {
  static final pending = ValueNotifier<PlacesMapFocusRequest?>(null);

  static void request({
    required String placeId,
    required double lat,
    required double lng,
  }) {
    pending.value = PlacesMapFocusRequest(
      placeId: placeId,
      lat: lat,
      lng: lng,
    );
  }
}
