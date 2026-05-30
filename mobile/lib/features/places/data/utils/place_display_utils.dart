import '../../../../core/constants/place_tags.dart';
import '../models/place_model.dart';

/// Text hiển thị cho list / subtitle — không phụ thuộc UI.
abstract final class PlaceDisplayUtils {
  static String subtitle(PlaceModel place, {required bool community}) {
    if (place.tags.isNotEmpty) {
      final tagLine = PlaceTags.labelsFor(place.tags);
      if (place.address != null && place.address!.isNotEmpty) {
        return '$tagLine · ${place.address}';
      }
      return tagLine;
    }
    if (place.address != null && place.address!.isNotEmpty) {
      return place.address!;
    }
    if (community) {
      return place.authorName ?? 'Người dùng';
    }
    return 'Địa điểm của bạn';
  }

  static String listSectionSubtitle({
    required int count,
    required Set<String> filterTags,
    required bool hasUserLocation,
    required int nearbyRadiusKm,
  }) {
    if (count == 0) {
      return filterTags.isEmpty ? 'Chưa có địa điểm' : 'Không có địa điểm phù hợp bộ lọc';
    }
    if (filterTags.isNotEmpty) {
      return '$count địa điểm · ${PlaceTags.labelsFor(filterTags.toList())}';
    }
    if (hasUserLocation) {
      return '$count địa điểm · trong $nearbyRadiusKm km';
    }
    return '$count địa điểm';
  }
}
