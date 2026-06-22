import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app.dart';
import '../../../../core/constants/map_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../data/models/place_model.dart';
import '../widgets/place_cover_image_picker.dart';

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
  final List<File> pickedImages = [];
  final List<String> existingPhotoUrls = [];
  static const maxPhotos = kMaxPlacePhotos;

  Future<void> loadForEdit(String placeId) async {
    loadingPlace = true;
    notifyListeners();

    try {
      final place = await SfinityApp.placeRepository.getPlace(
        placeId,
        placeNotFound: () => 'Place not found',
      );
      if (place.point != null) picked = place.point!;
      nameController.text = place.title;
      descriptionController.text = place.body;
      address = place.address;
      selectedTags = place.tags.toSet();
      isPublic = place.isPublic;
      if (address == null || address!.isEmpty) {
        await resolveAddress(picked);
      }
      await _loadExistingPhotos(placeId);
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

  Future<void> _loadExistingPhotos(String placeId) async {
    try {
      final result = await SfinityApp.placeEngagementRepository.getPhotos(placeId);
      existingPhotoUrls
        ..clear()
        ..addAll(result.photos.map((p) => p.imageUrl));
    } catch (_) {}
  }

  int get remainingPhotoSlots =>
      maxPhotos - existingPhotoUrls.length - pickedImages.length;

  void addPickedImages(List<File> files) {
    if (files.isEmpty) return;
    final room = remainingPhotoSlots;
    if (room <= 0) return;
    pickedImages.addAll(files.take(room));
    notifyListeners();
  }

  void removePickedAt(int index) {
    if (index < 0 || index >= pickedImages.length) return;
    pickedImages.removeAt(index);
    notifyListeners();
  }

  void clearPickedImages() {
    pickedImages.clear();
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

  Future<void> submit({
    String? editPlaceId,
    required String Function() nameRequired,
    required String Function() invalidCoordinates,
  }) async {
    if (nameController.text.trim().isEmpty) {
      throw nameRequired();
    }
    if (!MapConfig.isValidLatLng(picked)) {
      throw invalidCoordinates();
    }

    final isNewPlace = editPlaceId == null || editPlaceId.isEmpty;
    if (isNewPlace && !SfinityApp.userLimits.canCreatePlace) {
      throw 'PLACE_LIMIT';
    }

    loading = true;
    notifyListeners();

    try {
      late final String resultingPlaceId;

      final payload = PlaceUpsertPayload(
        title: nameController.text.trim(),
        body: descriptionController.text.trim().isEmpty
            ? 'Study place shared by user.'
            : descriptionController.text.trim(),
        latitude: picked.latitude,
        longitude: picked.longitude,
        address: address ??
            '${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}',
        tags: selectedTags.toList(),
        isPublic: isPublic,
      );

      if (editPlaceId != null && editPlaceId.isNotEmpty) {
        await SfinityApp.placeRepository.updatePlace(
          editPlaceId,
          payload,
          errorMsg: () => 'Cannot update place',
        );
        resultingPlaceId = editPlaceId;
      } else {
        final place = await SfinityApp.placeRepository.createPlace(
          payload,
          errorMsg: () => 'Cannot create place',
        );
        resultingPlaceId = place.id;
        await SfinityApp.userLimits.refresh();
      }

      final photoErrors = <String>[];
      for (final image in pickedImages) {
        try {
          await SfinityApp.placeEngagementRepository.uploadAndAddPhoto(
            resultingPlaceId,
            imageFile: image,
          );
        } on DioException catch (e) {
          photoErrors.add(ApiClient.instance.errorMessage(e));
        } catch (e) {
          photoErrors.add(e.toString());
        }
      }
      pickedImages.clear();

      if (photoErrors.isNotEmpty) {
        throw photoErrors.join('\n');
      }
    } on DioException catch (e) {
      throw ApiClient.instance.errorMessage(e);
    } catch (e) {
      if (e is String) rethrow;
      throw e.toString();
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
