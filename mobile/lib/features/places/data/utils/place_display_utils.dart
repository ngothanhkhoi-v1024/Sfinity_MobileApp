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
    int? minRating,
    required bool hasUserLocation,
    required int nearbyRadiusKm,
  }) {
    if (count == 0) {
      final hasFilters = filterTags.isNotEmpty || minRating != null;
      return hasFilters ? 'No places match filters' : 'No places yet';
    }

    final parts = <String>['$count places'];
    if (minRating != null) {
      parts.add('≥ $minRating★');
    }
    if (filterTags.isNotEmpty) {
      parts.add(PlaceTags.labelsFor(filterTags.toList()));
    } else if (hasUserLocation && minRating == null) {
      parts.add('within $nearbyRadiusKm km');
    }
    return parts.join(' · ');
  }
}
