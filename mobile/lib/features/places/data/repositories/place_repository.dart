import 'package:latlong2/latlong.dart';

import '../models/place_model.dart';

abstract class PlaceRepository {
  Future<List<PlaceModel>> listPlaces(PlaceListQuery query);

  Future<PlaceModel> getPlace(String id);

  Future<List<Map<String, dynamic>>> listDocumentsAtPlace(String placeId);

  Future<PlaceModel> createPlace(PlaceUpsertPayload payload);

  Future<PlaceModel> updatePlace(String id, PlaceUpsertPayload payload);

  Future<void> deletePlace(String id);

  Future<LatLng?> getCurrentLocation();
}
