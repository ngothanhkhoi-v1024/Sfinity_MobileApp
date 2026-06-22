import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../app.dart';
import '../../../../core/network/api_client.dart';
import '../utils/document_state.dart';

class DocumentListController extends ChangeNotifier {
  List<dynamic> allItems = [];
  List<dynamic> filteredItems = [];
  bool loading = true;
  String? error;
  String searchQuery = '';
  String selectedCategory = 'Tất cả';
  String selectedStatusFilter = 'Tất cả';
  bool communityMode = true;

  List<String> categories = ['Tất cả', 'Bài giảng', 'Đề thi', 'Ghi chú', 'Khác'];
  final List<String> statusFilters = [
    'Tất cả',
    'Chờ duyệt',
    'Đã duyệt',
    'Từ chối',
    'Chỉ mình tôi',
    'Bị ẩn',
  ];
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
      // Tải danh mục động từ database
      final dbCats = await SfinityApp.documentRepository.getCategories();
      final List<String> fetchedNames = dbCats
          .map((c) => (c['name'] as String?) ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      fetchedNames.remove('Tất cả');
      fetchedNames.remove('Khác');
      categories = ['Tất cả', ...fetchedNames, 'Khác'];

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
      final mapItem = Map<String, dynamic>.from(item as Map);
      final title = (mapItem['title']?.toString() ?? '').toLowerCase();
      final body = (mapItem['body']?.toString() ?? '').toLowerCase();
      final subjectCode = (mapItem['subjectCode']?.toString() ?? '').toLowerCase();

      final matchesSearch = title.contains(searchQuery) ||
          body.contains(searchQuery) ||
          subjectCode.contains(searchQuery);

      if (selectedCategory != 'Tất cả') {
        final categoryName = (mapItem['category'] as Map?)?['name']?.toString() ?? 'Khác';
        final knownCategories = categories.where((c) => c != 'Tất cả' && c != 'Khác').toList();
        final matchesCategory = categoryName.toLowerCase() == selectedCategory.toLowerCase() ||
            (selectedCategory == 'Khác' &&
                !knownCategories.any((kc) => kc.toLowerCase() == categoryName.toLowerCase()));
        if (!matchesCategory) return false;
      }

      if (!communityMode && selectedStatusFilter != 'Tất cả') {
        final visibility = documentVisibilityOf(mapItem);
        final moderation = documentModerationStatusOf(mapItem);
        final matchesStatus = switch (selectedStatusFilter) {
          'Chờ duyệt' =>
            visibility == documentVisibilityPublic &&
            moderation == documentModerationPending,
          'Đã duyệt' =>
            visibility == documentVisibilityPublic &&
            moderation == documentModerationApproved,
          'Từ chối' =>
            visibility == documentVisibilityPublic &&
            moderation == documentModerationRejected,
          'Chỉ mình tôi' => visibility == documentVisibilityPrivate,
          'Bị ẩn' =>
            visibility == documentVisibilityPublic &&
            moderation == documentModerationHidden,
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
