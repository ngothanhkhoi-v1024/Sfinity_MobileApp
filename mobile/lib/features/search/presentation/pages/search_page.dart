import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;

  // Rich UX content state
  List<String> _recentSearches = [];
  List<dynamic> _recommendations = [];
  bool _loadingRecommendations = false;

  // Popular search suggestions
  final List<Map<String, dynamic>> _popularSuggestions = const [
    {'label': 'Thư viện', 'color': Color(0xFFEF4444)},
    {'label': 'Café học tập', 'color': Color(0xFF10B981)},
    {'label': 'Giải tích', 'color': Color(0xFF3B82F6)},
    {'label': 'Đề thi đại cương', 'color': Color(0xFF8B5CF6)},
    {'label': 'Ghi chú', 'color': Color(0xFFF59E0B)},
  ];

  @override
  void initState() {
    super.initState();
    _query.addListener(() {
      setState(() {});
    });
    _loadRecentSearches();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearch(String q) async {
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_searches') ?? [];
    list.remove(q); // Prevent duplicates
    list.insert(0, q); // Push to front
    if (list.length > 5) list.removeLast(); // Keep top 5
    await prefs.setStringList('recent_searches', list);
    setState(() {
      _recentSearches = list;
    });
  }

  Future<void> _deleteSearch(String q) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_searches') ?? [];
    list.remove(q);
    await prefs.setStringList('recent_searches', list);
    setState(() {
      _recentSearches = list;
    });
  }

  Future<void> _clearAllRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      _recentSearches = [];
    });
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loadingRecommendations = true);
    try {
      final res = await ApiClient.instance.get('/document', query: {
        'publishedOnly': 'true',
        'limit': '6',
      });
      setState(() => _recommendations = res['items'] as List? ?? []);
    } catch (_) {
      // Silent catch
    } finally {
      setState(() => _loadingRecommendations = false);
    }
  }

  Future<void> _search({String? customQuery}) async {
    final q = customQuery ?? _query.text.trim();
    if (q.isEmpty) return;

    if (customQuery != null) {
      _query.text = q;
      // Put cursor at the end
      _query.selection = TextSelection.fromPosition(TextPosition(offset: q.length));
    }

    _saveSearch(q);

    setState(() {
      _loading = true;
    });
    try {
      final res = await ApiClient.instance.get('/document', query: {
        'search': q,
        'publishedOnly': 'true',
      });
      setState(() => _results = res['items'] as List? ?? []);
    } on DioException catch (_) {
      setState(() => _results = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  bool _isPlace(Map<String, dynamic> item) {
    if (item['type']?.toString() == 'place') return true;
    final body = item['body']?.toString() ?? '';
    return body.contains('type:place');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryOf(context);

    // If query was cleared and they aren't loading, reset the searched state so recommendations display
    final isQueryEmpty = _query.text.trim().isEmpty;
    final showSuggestions = isQueryEmpty && !_loading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.search,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.searchFill(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border(context),
                      ),
                    ),
                    child: TextField(
                      controller: _query,
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted(context)),
                        suffixIcon: _query.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _query.clear();
                                  setState(() {
                                    _results = [];
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ),

          Expanded(
            child: showSuggestions
                ? _buildSuggestions(isDark, primary)
                : _buildSearchResults(l10n, isDark, primary),
          ),
        ],
      ),
    );
  }

  // Build the rich suggestions UI shown BEFORE search
  Widget _buildSuggestions(bool isDark, Color primary) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. Recent Searches Section
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tìm kiếm gần đây',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.title(context),
                ),
              ),
              TextButton(
                onPressed: _clearAllRecent,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Xóa tất cả',
                  style: TextStyle(fontSize: 12, color: primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _recentSearches.length; i++) ...[
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.history_rounded, size: 18, color: AppColors.muted(context)),
                    title: Text(
                      _recentSearches[i],
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () => _deleteSearch(_recentSearches[i]),
                    ),
                    onTap: () => _search(customQuery: _recentSearches[i]),
                  ),
                  if (i < _recentSearches.length - 1)
                    Divider(height: 1, indent: 46, color: AppColors.divider(context)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 2. Popular Tags Suggestions Section
        Text(
          'Gợi ý tìm kiếm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.title(context),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSuggestions.map((suggestion) {
            final color = suggestion['color'] as Color;
            return ActionChip(
              backgroundColor: color.withValues(alpha: isDark ? 0.15 : 0.08),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              label: Text(
                suggestion['label'] as String,
                style: TextStyle(
                  color: isDark ? color.withValues(alpha: 0.95) : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              onPressed: () => _search(customQuery: suggestion['label'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 3. Recommended Items Section
        Text(
          'Đề xuất cho bạn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.title(context),
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingRecommendations)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        else if (_recommendations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Không có đề xuất nào',
                style: TextStyle(color: AppColors.muted(context), fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recommendations.length,
            itemBuilder: (context, idx) {
              final item = _recommendations[idx] as Map<String, dynamic>;
              final id = item['id']?.toString() ?? '';
              final title = item['title']?.toString() ?? '';
              final isPlace = _isPlace(item);
              final accentColor = isPlace ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: id.isEmpty
                        ? null
                        : () => context.push(isPlace ? '/places/$id' : '/document/$id'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border(context),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: isDark ? 0.18 : 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPlace ? Icons.place_rounded : Icons.description_rounded,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPlace ? 'Địa điểm học tập' : 'Tài liệu chia sẻ',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.muted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.muted(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // Build the search results view shown AFTER search is executed
  Widget _buildSearchResults(AppLocalizations l10n, bool isDark, Color primary) {
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.muted(context)),
            const SizedBox(height: 16),
            Text(
              l10n.noResultsFound,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.title(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm với từ khóa khác xem sao nhé',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final item = _results[i] as Map<String, dynamic>;
        final id = item['id']?.toString() ?? '';
        final title = item['title']?.toString() ?? '';
        final isPlace = _isPlace(item);
        final accentColor = isPlace ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: id.isEmpty
                  ? null
                  : () => context.push(isPlace ? '/places/$id' : '/document/$id'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border(context),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.18 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPlace ? Icons.place_rounded : Icons.description_rounded,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPlace ? 'Địa điểm học tập' : 'Tài liệu chia sẻ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.muted(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
