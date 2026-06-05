abstract class FavoritesRepository {
  Future<List<dynamic>> getFavorites();
  Future<void> deleteFavorite(String id);
}
