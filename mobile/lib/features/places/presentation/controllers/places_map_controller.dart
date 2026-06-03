import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app.dart';
import '../../../../core/constants/map_config.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/place_model.dart';
import '../../data/services/place_location_service.dart';
import '../../data/utils/place_display_utils.dart';

const placesNearbyRadiusKm = 50;

class PlacesMapController extends ChangeNotifier {
  PlacesMapController({
    PlaceLocationService? locationService,
  }) : _location = locationService ?? PlaceLocationService();

  final PlaceLocationService _location;

  LatLng center = MapConfig.defaultCenter;
  LatLng? myLocation;
  bool locating = false;
  bool loadingPlaces = true;
  bool communityMode = true;
  bool listView = false;
  String? locationHint;
  String searchQuery = '';
  Set<String> filterTags = {};

  List<PlaceModel> publicPlaces = [];
  List<PlaceModel> myPlaces = [];

  List<PlaceModel> get activePlaces => communityMode ? publicPlaces : myPlaces;

  List<PlaceModel> sortedActivePlaces() {
    return _location.sortByDistance(activePlaces, myLocation);
  }

  String distanceLabelFor(PlaceModel place, {String Function()? noLocationYet}) {
    if (place.distanceMeters != null) {
      return _location.formatDistanceMeters(place.distanceMeters);
    }
    final point = place.point;
    final me = myLocation;
    if (point == null || me == null) return noLocationYet?.call() ?? 'No location yet';
    return _location.distanceLabel(me, point);
  }

  String subtitleFor(PlaceModel place) =>
      PlaceDisplayUtils.subtitle(place, community: communityMode);

  String listSectionSubtitle(int count) => PlaceDisplayUtils.listSectionSubtitle(
        count: count,
        filterTags: filterTags,
        hasUserLocation: myLocation != null,
        nearbyRadiusKm: placesNearbyRadiusKm,
      );

  bool isOwnedByCurrentUser(PlaceModel place) {
    final currentUserId = SfinityApp.auth.user?['id']?.toString();
    return currentUserId != null &&
        place.authorId != null &&
        currentUserId == place.authorId;
  }

  Future<void> init() async {
    await loadPlaces();
    await initLocation();
  }

  Future<void> initLocation({String Function()? enableGPSHint, String Function()? cannotGetLocation}) async {
    if (locating) return;
    locating = true;
    locationHint = null;
    notifyListeners();

    try {
      final here = await SfinityApp.placeRepository.getCurrentLocation();
      if (here == null) {
        locating = false;
        locationHint = enableGPSHint?.call() ?? 'Enable GPS/location permission to see distances';
        notifyListeners();
        return;
      }
      center = here;
      myLocation = here;
      locating = false;
      notifyListeners();
      await loadPlaces();
    } catch (_) {
      locating = false;
      locationHint = cannotGetLocation?.call() ?? 'Cannot get current location';
      notifyListeners();
    }
  }

  Future<void> loadPlaces() async {
    loadingPlaces = true;
    notifyListeners();

    try {
      final me = myLocation;
      final search = searchQuery.trim();
      publicPlaces = await SfinityApp.placeRepository.listPlaces(
        PlaceListQuery(
          publishedOnly: true,
          lat: me?.latitude,
          lng: me?.longitude,
          radiusKm: me != null ? placesNearbyRadiusKm.toDouble() : null,
          search: search.isNotEmpty ? search : null,
          tags: filterTags,
        ),
      );

      final currentUserId = SfinityApp.auth.user?['id']?.toString();
      if (currentUserId != null && currentUserId.isNotEmpty) {
        myPlaces = await SfinityApp.placeRepository.listPlaces(
          PlaceListQuery(
            authorId: currentUserId,
            search: search.isNotEmpty ? search : null,
            tags: filterTags,
          ),
        );
      } else {
        myPlaces = [];
      }
      loadingPlaces = false;
      locationHint = null;
    } on DioException catch (e) {
      loadingPlaces = false;
      locationHint = ApiClient.instance.errorMessage(e);
    } catch (_) {
      loadingPlaces = false;
    }
    notifyListeners();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
  }

  void setCommunityMode(bool value) {
    communityMode = value;
    notifyListeners();
  }

  void setListView(bool value) {
    listView = value;
    notifyListeners();
  }

  void setFilterTags(Set<String> tags) {
    filterTags = tags;
    notifyListeners();
  }

  void updateCenter(LatLng value) {
    center = value;
  }

  Future<bool> deletePlace(String placeId) async {
    try {
      await SfinityApp.placeRepository.deletePlace(placeId);
      await loadPlaces();
      return true;
    } on DioException {
      rethrow;
    }
  }

}
