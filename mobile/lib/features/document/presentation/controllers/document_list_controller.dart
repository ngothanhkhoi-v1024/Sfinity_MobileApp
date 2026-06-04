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
  String selectedStatusFilter = 'Tất cả';
  bool communityMode = true;

  final List<String> categories = ['Tất cả', 'Bài giảng', 'Đề thi', 'Ghi chú', 'Khác'];
  final List<String> statusFilters = ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Từ chối', 'Bản nháp', 'Bị ẩn'];
  final TextEditingController searchController = TextEditingController();

  void setCommunityMode(bool val) {
    communityMode = val;
    selectedStatusFilter = 'Tất cả';
    selectedCategory = 'Tất cả';
    load();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final currentUserId = SfinityApp.auth.user?['id']?.toString();
      final res = await SfinityApp.documentRepository.getDocuments(
        publishedOnly: communityMode ? true : null,
        authorId: communityMode ? null : currentUserId,
        limit: 50,
      );
      allItems = res['items'] as List? ?? [];
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

      if (selectedCategory != 'Tất cả') {
        final categoryName = (item['category'] as Map?)?['name']?.toString() ?? 'Khác';
        final matchesCategory = categoryName.toLowerCase() == selectedCategory.toLowerCase() ||
            (selectedCategory == 'Khác' &&
                !categories.sublist(1, 4).contains(categoryName));
        if (!matchesCategory) return false;
      }

      if (!communityMode && selectedStatusFilter != 'Tất cả') {
        final status = item['status']?.toString();
        final matchesStatus = switch (selectedStatusFilter) {
          'Chờ duyệt' => status == 'PENDING',
          'Đã duyệt' => status == 'PUBLISHED',
          'Từ chối' => status == 'REJECTED',
          'Bản nháp' => status == 'DRAFT',
          'Bị ẩn' => status == 'HIDDEN',
          _ => true,
        };
        if (!matchesStatus) return false;
      }

      return matchesSearch;
    }).toList();
    notifyListeners();
  }

  void changeCategory(String category) {
    selectedCategory = category;
    filterItems();
  }

  void changeStatusFilter(String status) {
    selectedStatusFilter = status;
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
