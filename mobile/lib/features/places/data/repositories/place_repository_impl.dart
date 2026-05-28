import 'package:latlong2/latlong.dart';

import '../../../../core/constants/place_tags.dart';
import '../mappers/place_mapper.dart';
import '../models/place_model.dart';
import '../services/place_api_service.dart';
import '../services/place_location_service.dart';
import 'place_repository.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  PlaceRepositoryImpl(this._api, this._location);

  final PlaceApiService _api;
  final PlaceLocationService _location;

  @override
  Future<List<PlaceModel>> listPlaces(PlaceListQuery query) async {
    final tagsQuery = PlaceTags.toQueryParam(query.tags);
    final res = await _api.listPlaces(
      search: query.search?.isNotEmpty == true ? query.search : null,
      tags: tagsQuery.isNotEmpty ? tagsQuery : null,
      lat: query.lat,
      lng: query.lng,
      radiusKm: query.radiusKm,
      authorId: query.authorId,
      publishedOnly: query.publishedOnly,
      limit: query.limit,
    );
    return PlaceMapper.listFromRaw(res['items'] as List? ?? []);
  }

  @override
  Future<PlaceModel> getPlace(String id) async {
    final res = await _api.getPlace(id);
    final place = PlaceMapper.fromJson(Map<String, dynamic>.from(res));
    if (place == null) {
      throw Exception('Địa điểm không có tọa độ hợp lệ');
    }
    return place;
  }

  @override
  Future<List<Map<String, dynamic>>> listDocumentsAtPlace(String placeId) async {
    final res = await _api.listDocumentsAtPlace(placeId);
    final items = res['items'] as List? ?? [];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Future<PlaceModel> createPlace(PlaceUpsertPayload payload) async {
    final res = await _api.createPlace(payload.toJson());
    final place = PlaceMapper.fromJson(Map<String, dynamic>.from(res));
    if (place == null) throw Exception('Không tạo được địa điểm');
    return place;
  }

  @override
  Future<PlaceModel> updatePlace(String id, PlaceUpsertPayload payload) async {
    final res = await _api.updatePlace(id, payload.toJson());
    final place = PlaceMapper.fromJson(Map<String, dynamic>.from(res));
    if (place == null) throw Exception('Không cập nhật được địa điểm');
    return place;
  }

  @override
  Future<void> deletePlace(String id) => _api.deletePlace(id);

  @override
  Future<LatLng?> getCurrentLocation() => _location.getCurrentLocation();
}
