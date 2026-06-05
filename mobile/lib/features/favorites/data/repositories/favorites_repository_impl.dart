import '../services/favorites_api_service.dart';
import 'favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesApiService _apiService;

  FavoritesRepositoryImpl(this._apiService);

  @override
  Future<List<dynamic>> getFavorites() async {
    return await _apiService.getFavorites();
  }

  @override
  Future<void> deleteFavorite(String id) async {
    await _apiService.deleteFavorite(id);
  }
}
