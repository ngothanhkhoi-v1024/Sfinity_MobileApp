import 'package:latlong2/latlong.dart';

import '../models/place_model.dart';

abstract class PlaceRepository {
  Future<List<PlaceModel>> listPlaces(PlaceListQuery query);

  Future<PlaceModel> getPlace(String id, {String Function()? placeNotFound});

  Future<List<Map<String, dynamic>>> listDocumentsAtPlace(String placeId);

  Future<PlaceModel> createPlace(PlaceUpsertPayload payload, {String Function()? errorMsg});

  Future<PlaceModel> updatePlace(String id, PlaceUpsertPayload payload, {String Function()? errorMsg});

  Future<void> deletePlace(String id);

  Future<LatLng?> getCurrentLocation();
}
