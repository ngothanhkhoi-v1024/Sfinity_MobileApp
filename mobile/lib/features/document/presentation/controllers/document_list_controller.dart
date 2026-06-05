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
  String selectedCategory = 'Táº¥t cáº£';
  String selectedStatusFilter = 'Táº¥t cáº£';
  bool communityMode = true;

  final List<String> categories = ['Táº¥t cáº£', 'BĂ i giáº£ng', 'Äá» thi', 'Ghi chĂº', 'KhĂ¡c'];
  final List<String> statusFilters = [
    'Táº¥t cáº£',
    'Chá» duyá»‡t',
    'ÄĂ£ duyá»‡t',
    'Tá»« chá»‘i',
    'Chá»‰ mĂ¬nh tĂ´i',
    'Bá»‹ áº©n',
  ];
  final TextEditingController searchController = TextEditingController();

  void setCommunityMode(bool val) {
    communityMode = val;
    selectedStatusFilter = 'Táº¥t cáº£';
    selectedCategory = 'Táº¥t cáº£';
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
      final mapItem = Map<String, dynamic>.from(item as Map);
      final title = (mapItem['title']?.toString() ?? '').toLowerCase();
      final body = (mapItem['body']?.toString() ?? '').toLowerCase();
      final subjectCode = (mapItem['subjectCode']?.toString() ?? '').toLowerCase();

      final matchesSearch = title.contains(searchQuery) ||
          body.contains(searchQuery) ||
          subjectCode.contains(searchQuery);

      if (selectedCategory != 'Táº¥t cáº£') {
        final categoryName = (mapItem['category'] as Map?)?['name']?.toString() ?? 'KhĂ¡c';
        final matchesCategory = categoryName.toLowerCase() == selectedCategory.toLowerCase() ||
            (selectedCategory == 'KhĂ¡c' &&
                !categories.sublist(1, 4).contains(categoryName));
        if (!matchesCategory) return false;
      }

      if (!communityMode && selectedStatusFilter != 'Táº¥t cáº£') {
        final visibility = documentVisibilityOf(mapItem);
        final moderation = documentModerationStatusOf(mapItem);
        final matchesStatus = switch (selectedStatusFilter) {
          'Chá» duyá»‡t' =>
            visibility == documentVisibilityPublic &&
            moderation == documentModerationPending,
          'ÄĂ£ duyá»‡t' =>
            visibility == documentVisibilityPublic &&
            moderation == documentModerationApproved,
          'Tá»« chá»‘i' =>
            visibility == documentVisibilityPublic &&
            moderation == documentModerationRejected,
          'Chá»‰ mĂ¬nh tĂ´i' => visibility == documentVisibilityPrivate,
          'Bá»‹ áº©n' =>
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
