import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../../../../core/network/api_client.dart';

class DocumentListController extends ChangeNotifier {
  List<dynamic> allItems = [];
  List<dynamic> filteredItems = [];
  bool loading = true;
  String? error;
  String searchQuery = '';
  String selectedCategory = 'Tất cả';

  final List<String> categories = ['Tất cả', 'Bài giảng', 'Đề thi', 'Ghi chú', 'Khác'];
  final TextEditingController searchController = TextEditingController();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await SfinityApp.documentRepository.getDocuments(
        publishedOnly: true,
        limit: 50,
      );
      final raw = res['items'] as List? ?? [];
      allItems = raw.where((e) {
        final itemMap = e as Map<String, dynamic>;
        final type = itemMap['type']?.toString();
        if (type != null) {
          return type == 'document';
        }
        final body = itemMap['body']?.toString() ?? '';
        return !body.contains('type:place');
      }).toList();
      filterItems();
    } on DioException catch (e) {
      error = ApiClient.instance.errorMessage(e);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void filterItems() {
    filteredItems = allItems.where((item) {
      final title = (item['title']?.toString() ?? '').toLowerCase();
      final body = (item['body']?.toString() ?? '').toLowerCase();
      final subjectCode = (item['subjectCode']?.toString() ?? '').toLowerCase();
      final tags = (item['tags'] as List? ?? []).map((t) => t.toString().toLowerCase()).toList();

      final matchesSearch = title.contains(searchQuery) ||
          body.contains(searchQuery) ||
          subjectCode.contains(searchQuery) ||
          tags.any((tag) => tag.contains(searchQuery));

      if (selectedCategory == 'Tất cả') {
        return matchesSearch;
      }

      final categoryName = (item['category'] as Map?)?['name']?.toString() ?? 'Khác';
      final matchesCategory = categoryName.toLowerCase() == selectedCategory.toLowerCase() ||
          (selectedCategory == 'Khác' &&
              !categories.sublist(1, 4).contains(categoryName));

      return matchesSearch && matchesCategory;
    }).toList();
    notifyListeners();
  }

  void changeCategory(String category) {
    selectedCategory = category;
    filterItems();
  }

  void updateSearchQuery(String val) {
    searchQuery = val.trim().toLowerCase();
    filterItems();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery = '';
    filterItems();
  }
}
