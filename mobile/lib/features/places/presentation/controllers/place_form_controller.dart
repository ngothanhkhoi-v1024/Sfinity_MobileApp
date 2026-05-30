import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app.dart';
import '../../../../core/constants/map_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../data/models/place_model.dart';

class PlaceFormController extends ChangeNotifier {
  PlaceFormController({
    GeocodingService? geocoding,
  }) : _geocoding = geocoding ?? GeocodingService();

  final GeocodingService _geocoding;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final searchController = TextEditingController();

  LatLng picked = MapConfig.defaultCenter;
  String? address;
  Set<String> selectedTags = {};
  bool isPublic = true;
  bool loading = false;
  bool loadingPlace = false;
  bool geocodingAddress = false;
  List<GeocodingResult> searchResults = [];

  Future<void> loadForEdit(String placeId) async {
    loadingPlace = true;
    notifyListeners();

    try {
      final place = await SfinityApp.placeRepository.getPlace(placeId);
      if (place.point != null) picked = place.point!;
      nameController.text = place.title;
      descriptionController.text = place.body;
      address = place.address;
      selectedTags = place.tags.toSet();
      isPublic = place.isPublic;
      if (address == null || address!.isEmpty) {
        await resolveAddress(picked);
      }
    } on DioException catch (e) {
      throw ApiClient.instance.errorMessage(e);
    } finally {
      loadingPlace = false;
      notifyListeners();
    }
  }

  void setPickedFromCoords(double lat, double lng) {
    final point = MapConfig.latLngFromCoords(lat, lng);
    if (point == null) return;
    picked = point;
    resolveAddress(point);
    notifyListeners();
  }

  Future<void> resolveAddress(LatLng point) async {
    geocodingAddress = true;
    notifyListeners();
    address = await _geocoding.reverseAddress(point.latitude, point.longitude);
    geocodingAddress = false;
    notifyListeners();
  }

  void onMapTap(LatLng point) {
    if (!MapConfig.isValidLatLng(point)) return;
    picked = point;
    searchResults = [];
    notifyListeners();
    resolveAddress(point);
  }

  Future<void> runSearch() async {
    searchResults = await _geocoding.search(searchController.text);
    notifyListeners();
  }

  void selectSearchResult(GeocodingResult result) {
    final lat = result.lat;
    final lng = result.lng;
    if (lat == null || lng == null) return;
    final point = MapConfig.latLngFromCoords(lat, lng);
    if (point == null) return;
    picked = point;
    address = result.displayName;
    searchResults = [];
    searchController.text = result.displayName;
    notifyListeners();
  }

  Future<void> submit({String? editPlaceId}) async {
    if (nameController.text.trim().isEmpty) {
      throw 'Nhập tên địa điểm';
    }
    if (!MapConfig.isValidLatLng(picked)) {
      throw 'Chọn vị trí hợp lệ trên bản đồ';
    }

    loading = true;
    notifyListeners();

    try {
      final payload = PlaceUpsertPayload(
        title: nameController.text.trim(),
        body: descriptionController.text.trim().isEmpty
            ? 'Địa điểm học tập do người dùng chia sẻ.'
            : descriptionController.text.trim(),
        latitude: picked.latitude,
        longitude: picked.longitude,
        address: address ??
            '${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}',
        tags: selectedTags.toList(),
        isPublic: isPublic,
      );

      if (editPlaceId != null && editPlaceId.isNotEmpty) {
        await SfinityApp.placeRepository.updatePlace(editPlaceId, payload);
      } else {
        await SfinityApp.placeRepository.createPlace(payload);
      }
    } on DioException catch (e) {
      throw ApiClient.instance.errorMessage(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setSelectedTags(Set<String> tags) {
    selectedTags = tags;
    notifyListeners();
  }

  void setIsPublic(bool value) {
    isPublic = value;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
