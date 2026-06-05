import '../../../../../core/network/api_client.dart';

class FavoritesApiService {
  final ApiClient _apiClient;

  FavoritesApiService(this._apiClient);

  Future<List<dynamic>> getFavorites() async {
    return await _apiClient.getList('/favorites');
  }

  Future<void> deleteFavorite(String id) async {
    await _apiClient.delete('/favorites/$id');
  }
}
