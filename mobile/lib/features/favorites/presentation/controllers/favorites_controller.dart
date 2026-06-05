import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../../../../core/network/api_client.dart';

class FavoritesController extends ChangeNotifier {
  List<dynamic> allItems = [];
  bool loading = true;
  String? error;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      allItems = await SfinityApp.favoritesRepository.getFavorites();
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<dynamic> getFilteredItems(String filterType) {
    return allItems.where((fav) {
      final document = fav['document'] as Map<String, dynamic>?;
      if (document == null) return false;

      final type = document['type']?.toString();
      if (filterType == 'document' && type != 'document') return false;
      if (filterType == 'place' && type != 'place') return false;

      if (searchQuery.isEmpty) return true;

      final title = document['title']?.toString().toLowerCase() ?? '';
      final body = document['body']?.toString().toLowerCase() ?? '';
      final address = document['address']?.toString().toLowerCase() ?? '';
      final zone = document['zone']?.toString().toLowerCase() ?? '';
      final subjectCode = document['subjectCode']?.toString().toLowerCase() ?? '';

      return title.contains(searchQuery) ||
          body.contains(searchQuery) ||
          address.contains(searchQuery) ||
          zone.contains(searchQuery) ||
          subjectCode.contains(searchQuery);
    }).toList();
  }

  void updateSearchQuery(String val) {
    searchQuery = val.trim().toLowerCase();
    notifyListeners();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery = '';
    notifyListeners();
  }

  Map<String, dynamic>? removeItemLocally(dynamic fav) {
    final originalIndex = allItems.indexOf(fav);
    if (originalIndex != -1) {
      allItems.removeAt(originalIndex);
      notifyListeners();
      return {'index': originalIndex, 'item': fav};
    }
    return null;
  }

  void insertItemLocally(int index, dynamic item) {
    allItems.insert(index, item);
    notifyListeners();
  }

  Future<void> deleteFavoriteOnServer(String id) async {
    await SfinityApp.favoritesRepository.deleteFavorite(id);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
