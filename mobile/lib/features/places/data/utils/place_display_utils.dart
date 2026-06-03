import '../../../../core/constants/place_tags.dart';
import '../../../../core/i18n/app_text.dart';
import '../models/place_model.dart';

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
      return place.authorName ?? 'User';
    }
    return 'Your place';
  }

  static String listSectionSubtitle({
    required int count,
    required Set<String> filterTags,
    required bool hasUserLocation,
    required int nearbyRadiusKm,
  }) {
    if (count == 0) {
      return filterTags.isEmpty ? 'No places yet' : 'No places match filters';
    }
    if (filterTags.isNotEmpty) {
      return '$count places · ${PlaceTags.labelsFor(filterTags.toList())}';
    }
    if (hasUserLocation) {
      return '$count places · within $nearbyRadiusKm km';
    }
    return '$count places';
  }
}
