import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../friendships/data/models/friend_model.dart';
import '../../../study_near_me/presentation/controllers/study_near_me_controller.dart';
import '../../../study_near_me/presentation/widgets/study_near_me_results_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/explore_feed_list.dart';
import '../widgets/explore_insights_carousel.dart';
import '../widgets/explore_top_panel.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static const _feedPageSize = 6;

  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  late final StudyNearMeController _studyNearMeCtrl;
  final _searchController = TextEditingController();
  ExploreFilter _filter = ExploreFilter.all;
  int _feedVisibleCount = _feedPageSize;
  bool _searchingApi = false;
  List<dynamic>? _apiSearchResults;
  Timer? _debounce;
  bool _showingSaved = false;
  List<Map<String, dynamic>> _savedItems = [];
  bool _loadingSaved = false;
  String? _savedError;
  List<Map<String, dynamic>> _trendingPlaces = [];
  List<Map<String, dynamic>> _trendingDocuments = [];
  List<Map<String, dynamic>> _weeklyDays = [];
  int _weeklyTotalPlaces = 0;
  int _weeklyTotalDownloads = 0;
  List<Map<String, dynamic>> _topUsers = [];
  bool _loadingExploreMeta = true;

  @override
  void initState() {
    super.initState();
    _studyNearMeCtrl = StudyNearMeController();
    _studyNearMeCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(_onSearchTextChanged);
    _load();
    _loadExploreMeta();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _studyNearMeCtrl.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final q = _searchController.text.trim();
      if (q.isEmpty) {
        setState(() {
          _apiSearchResults = null;
          _feedVisibleCount = _feedPageSize;
        });
        return;
      }
      _runApiSearch(q);
    });
    setState(() {
      _feedVisibleCount = _feedPageSize;
    });
  }

  void _resetFeedPagination() {
    _feedVisibleCount = _feedPageSize;
  }

  void _onFilterChanged(ExploreFilter filter) {
    setState(() {
      _filter = filter;
      _resetFeedPagination();
    });
  }

  void _loadMoreFeed() {
    setState(() {
      _feedVisibleCount += _feedPageSize;
    });
  }

  List<Map<String, dynamic>> _parseFeedItems(dynamic res) {
    return (res['items'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  DateTime _itemCreatedAt(Map<String, dynamic> item) {
    return DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime(0);
  }

  List<Map<String, dynamic>> _mergeFeedItems(
    List<Map<String, dynamic>> docs,
    List<Map<String, dynamic>> places,
  ) {
    final merged = [...docs, ...places];
    merged.sort((a, b) => _itemCreatedAt(b).compareTo(_itemCreatedAt(a)));
    return merged;
  }

  Future<void> _runApiSearch(String query) async {
    setState(() => _searchingApi = true);
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/document', query: {
          'search': query,
          'publishedOnly': 'true',
          'limit': '30',
        }),
        ApiClient.instance.get('/places', query: {
          'search': query,
          'publishedOnly': 'true',
          'limit': '30',
        }),
      ]);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _apiSearchResults = _mergeFeedItems(
          _parseFeedItems(results[0]),
          _parseFeedItems(results[1]),
        );
      });
    } on DioException {
      if (mounted && _searchController.text.trim() == query) {
        setState(() => _apiSearchResults = []);
      }
    } finally {
      if (mounted) setState(() => _searchingApi = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _apiSearchResults = null;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {});
  }

  Future<void> _onStudyNearMe() async {
    final ok = await _studyNearMeCtrl.loadNearby();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_studyNearMeCtrl.error ?? context.l10n.noResultsFound)),
      );
      return;
    }
    final result = _studyNearMeCtrl.result;
    if (result != null) {
      await StudyNearMeResultsSheet.show(
        context,
        controller: _studyNearMeCtrl,
        onRefresh: () => _studyNearMeCtrl.loadNearby(),
      );
    }
  }

  Future<void> _loadExploreMeta() async {
    setState(() => _loadingExploreMeta = true);
    try {
      final featured = await ApiClient.instance.get('/explore/featured');
      _trendingPlaces = (featured['trendingPlaces'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      _trendingDocuments = (featured['trendingDocuments'] as List? ?? [])
          .cast<Map<String, dynamic>>();
    } on DioException {
      _trendingPlaces = [];
      _trendingDocuments = [];
    }

    try {
      final stats = await ApiClient.instance.get('/explore/weekly-stats');
      _weeklyDays = (stats['days'] as List? ?? []).cast<Map<String, dynamic>>();
      _weeklyTotalPlaces = (stats['totalPlaces'] as num?)?.toInt() ?? 0;
      _weeklyTotalDownloads = (stats['totalDownloads'] as num?)?.toInt() ?? 0;
    } on DioException {
      _weeklyDays = List.generate(
        7,
        (i) => {
          'label': ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][i],
          'places': 0,
          'downloads': 0,
        },
      );
      _weeklyTotalPlaces = 0;
      _weeklyTotalDownloads = 0;
    }

    try {
      final topUsers = await ApiClient.instance.get('/explore/top-users');
      _topUsers = (topUsers['users'] as List? ?? []).cast<Map<String, dynamic>>();
    } on DioException {
      _topUsers = [];
    } finally {
      if (mounted) setState(() => _loadingExploreMeta = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/document', query: {
          'publishedOnly': 'true',
          'limit': '20',
        }),
        ApiClient.instance.get('/places', query: {
          'publishedOnly': 'true',
          'limit': '20',
        }),
      ]);
      _items = _mergeFeedItems(
        _parseFeedItems(results[0]),
        _parseFeedItems(results[1]),
      );
      _apiSearchResults = null;
    } on DioException catch (e) {
      _error = ApiClient.instance.errorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isPlace(Map<String, dynamic> item) {
    if (item['type']?.toString() == 'place') return true;
    final body = item['body']?.toString() ?? '';
    return body.contains('type:place');
  }

  List<Map<String, dynamic>> get _sourceItems {
    if (_showingSaved) return _savedItems;
    final raw = _searchController.text.trim().isNotEmpty && _apiSearchResults != null
        ? _apiSearchResults!
        : _items;
    return raw.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> get _visibleItems {
    final q = _searchController.text.trim().toLowerCase();
    return _sourceItems.where((item) {
      if (_filter == ExploreFilter.place && !_isPlace(item)) return false;
      if (_filter == ExploreFilter.document && _isPlace(item)) return false;
      if (q.isEmpty) return true;
      if (!_showingSaved && _apiSearchResults != null) return true;
      final title = item['title']?.toString().toLowerCase() ?? '';
      return title.contains(q);
    }).toList();
  }

  int get _placeCount => _items.where((e) => _isPlace(e as Map<String, dynamic>)).length;
  int get _docCount => _items.length - _placeCount;
  int get _savedPlaceCount => _savedItems.where(_isPlace).length;
  int get _savedDocCount => _savedItems.length - _savedPlaceCount;

  Future<void> _loadFavorites() async {
    setState(() {
      _loadingSaved = true;
      _savedError = null;
    });
    try {
      final favs = await ApiClient.instance.getList('/favorites');
      _savedItems = favs
          .map((f) => (f as Map<String, dynamic>)['document'])
          .whereType<Map<String, dynamic>>()
          .toList();
    } on DioException catch (e) {
      _savedError = ApiClient.instance.errorMessage(e);
      _savedItems = [];
    } finally {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  Future<void> _toggleSavedView() async {
    if (_showingSaved) {
      setState(() {
        _showingSaved = false;
        _resetFeedPagination();
      });
      return;
    }
    setState(() {
      _showingSaved = true;
      _resetFeedPagination();
    });
    await _loadFavorites();
  }

  Future<void> _onRefresh() async {
    setState(_resetFeedPagination);
    await Future.wait([
      if (_showingSaved) _loadFavorites() else _load(),
      _loadExploreMeta(),
    ]);
  }

  void _openItem(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    if (_isPlace(item)) {
      context.push('/places/$id');
    } else {
      context.push('/document/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _ExploreLoadingView();
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final visible = _visibleItems;
    final paginated = visible.take(_feedVisibleCount).toList();
    final hasMoreFeed = _feedVisibleCount < visible.length;
    final isSearching = _searchController.text.trim().isNotEmpty;
    final displayPlaceCount = _showingSaved ? _savedPlaceCount : _placeCount;
    final displayDocCount = _showingSaved ? _savedDocCount : _docCount;
    final sectionTitle = _showingSaved
        ? l10n.saved
        : (isSearching ? l10n.results : l10n.newest);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      edgeOffset: 8,
      color: primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ExploreTopPanel(
                    searchController: _searchController,
                    searchHint: l10n.searchHint,
                    onSearchChanged: (_) => setState(() => _resetFeedPagination()),
                    onSearchSubmitted: (q) {
                      if (q.trim().isNotEmpty) _runApiSearch(q.trim());
                    },
                  ),
                  if (_searchingApi)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.loading,
                            style: TextStyle(fontSize: 12, color: primary),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  _ExploreQuickActions(
                    studyNearMeLoading: _studyNearMeCtrl.loading,
                    onStudyNearMe: _onStudyNearMe,
                    savedLabel: l10n.saved,
                    savedSelected: _showingSaved,
                    onSaved: _toggleSavedView,
                    onCreate: () => context.push(
                      RouteNames.documentCreate,
                      extra: const {'contentType': 'document'},
                    ),
                    primary: primary,
                  ),
                  if (!isSearching && !_showingSaved) ...[
                    if (!_loadingExploreMeta &&
                        (_trendingPlaces.isNotEmpty ||
                            _trendingDocuments.isNotEmpty ||
                            _weeklyDays.isNotEmpty ||
                            _topUsers.isNotEmpty)) ...[
                      const SizedBox(height: 12),
                      ExploreInsightsCarousel(
                        trendingPlaces: _trendingPlaces,
                        trendingDocuments: _trendingDocuments,
                        weeklyDays: _weeklyDays,
                        totalPlaces: _weeklyTotalPlaces,
                        totalDownloads: _weeklyTotalDownloads,
                        topUsers: _topUsers,
                        onPlaceTap: (item) {
                          final id = item['id']?.toString() ?? '';
                          if (id.isNotEmpty) context.push('/places/$id');
                        },
                        onDocumentTap: (item) {
                          final id = item['id']?.toString() ?? '';
                          if (id.isNotEmpty) context.push('/document/$id');
                        },
                        onUserTap: (user) {
                          final id = user['id']?.toString() ?? '';
                          if (id.isEmpty) return;
                          context.push(
                            RouteNames.viewProfile,
                            extra: FriendUser(
                              id: id,
                              name: user['name']?.toString() ?? '',
                              avatar: user['avatar']?.toString(),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  ExploreFilterRow(
                    filter: _filter,
                    primary: primary,
                    onChanged: _onFilterChanged,
                  ),
                  const SizedBox(height: 10),
                  ExploreFeedSectionHeader(
                    title: sectionTitle,
                    count: visible.length,
                    showingSaved: _showingSaved,
                    placeCount: displayPlaceCount,
                    docCount: displayDocCount,
                    subtitle: visible.isNotEmpty
                        ? l10n.exploreShowingCount(paginated.length, visible.length)
                        : null,
                  ),
                  if (isSearching && visible.isEmpty && !_searchingApi)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: _ExploreNoResults(
                        query: _searchController.text.trim(),
                        isDark: isDark,
                        onClear: _clearSearch,
                      ),
                    ),
                  const SizedBox(height: 10),
                ]),
              ),
            ),
          ),
          if (_showingSaved && _loadingSaved)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Padding(
                padding: EdgeInsets.only(bottom: 80),
                child: CircularProgressIndicator(),
              )),
            )
          else if (_showingSaved && _savedError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: ErrorView(message: _savedError!, onRetry: _loadFavorites),
              ),
            )
          else if (_showingSaved && visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: _ExploreSavedEmptyState(message: l10n.saved, isDark: isDark),
              ),
            )
          else if (!_showingSaved && !isSearching && _items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: _ExploreEmptyState(isDark: isDark),
              ),
            )
          else if (visible.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == paginated.length) {
                      return ExploreFeedLoadMore(
                        hasMore: hasMoreFeed,
                        remaining: visible.length - paginated.length,
                        onLoadMore: _loadMoreFeed,
                      );
                    }
                    final item = paginated[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < paginated.length - 1 ? 10 : 0),
                      child: ExploreFeedCard(
                        item: item,
                        isPlace: _isPlace(item),
                        onTap: () => _openItem(item),
                      ),
                    );
                  },
                  childCount: paginated.length + 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExploreQuickActions extends StatelessWidget {
  const _ExploreQuickActions({
    required this.studyNearMeLoading,
    required this.onStudyNearMe,
    required this.savedLabel,
    required this.savedSelected,
    required this.onSaved,
    required this.onCreate,
    required this.primary,
  });

  final bool studyNearMeLoading;
  final VoidCallback? onStudyNearMe;
  final String savedLabel;
  final bool savedSelected;
  final VoidCallback onSaved;
  final VoidCallback onCreate;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        _CompactActionChip(
          icon: Icons.near_me_outlined,
          label: l10n.studyNearMe,
          loading: studyNearMeLoading,
          accent: AppColors.secondary,
          onTap: studyNearMeLoading ? null : onStudyNearMe,
        ),
        const SizedBox(width: 8),
        _CompactActionChip(
          icon: Icons.bookmark_outline_rounded,
          label: savedLabel,
          selected: savedSelected,
          accent: primary,
          onTap: onSaved,
        ),
        const SizedBox(width: 8),
        _CompactActionChip(
          icon: Icons.add_rounded,
          label: l10n.share,
          accent: primary,
          onTap: onCreate,
        ),
      ],
    );
  }
}

class _CompactActionChip extends StatelessWidget {
  const _CompactActionChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.selected = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback? onTap;
  final bool selected;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? accent.withValues(alpha: 0.45) : AppColors.border(context),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                  )
                else
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? accent : AppColors.muted(context),
                  ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? accent : AppColors.title(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreNoResults extends StatelessWidget {
  const _ExploreNoResults({
    required this.query,
    required this.isDark,
    required this.onClear,
  });

  final String query;
  final bool isDark;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade500),
        const SizedBox(height: 8),
        Text(l10n.noSearchResults(query)),
        TextButton(onPressed: onClear, child: Text(l10n.clearSearch)),
      ],
    );
  }
}

class _ExploreEmptyState extends StatelessWidget {
  const _ExploreEmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_outlined, size: 36, color: muted),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noResultsFound,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.noResultsFound,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ExploreSavedEmptyState extends StatelessWidget {
  const _ExploreSavedEmptyState({required this.message, required this.isDark});

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border_rounded, size: 36, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.saved,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, height: 1.4, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ExploreLoadingView extends StatelessWidget {
  const _ExploreLoadingView();

  @override
  Widget build(BuildContext context) {
    final skeleton = AppColors.chipBg(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(height: 48, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Container(height: 40, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 40, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 40, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(10)))),
          ],
        ),
        const SizedBox(height: 12),
        Container(height: 150, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 12),
        Container(height: 36, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(height: 18, width: 90, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(6))),
            const Spacer(),
            Container(height: 22, width: 52, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 6),
            Container(height: 22, width: 52, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(8))),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 72,
                decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(16)),
              ),
            )),
      ],
    );
  }
}
