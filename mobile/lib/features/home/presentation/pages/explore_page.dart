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
import '../widgets/explore_featured_section.dart';
import '../widgets/explore_top_panel.dart';
import '../widgets/explore_top_users_section.dart';
import '../widgets/explore_weekly_chart.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  late final StudyNearMeController _studyNearMeCtrl;
  final _searchController = TextEditingController();
  ExploreFilter _filter = ExploreFilter.all;
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
        setState(() => _apiSearchResults = null);
        return;
      }
      _runApiSearch(q);
    });
    setState(() {});
  }

  Future<void> _runApiSearch(String query) async {
    setState(() => _searchingApi = true);
    try {
      final res = await ApiClient.instance.get('/document', query: {
        'search': query,
        'publishedOnly': 'true',
        'limit': '30',
      });
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() => _apiSearchResults = res['items'] as List? ?? []);
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
        result: result,
        onRetry: _onStudyNearMe,
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
      final res = await ApiClient.instance.get('/document', query: {
        'publishedOnly': 'true',
        'limit': '20',
      });
      _items = res['items'] as List? ?? [];
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
      setState(() => _showingSaved = false);
      return;
    }
    setState(() => _showingSaved = true);
    await _loadFavorites();
  }

  Future<void> _onRefresh() async {
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
                    filter: _filter,
                    primary: primary,
                    onFilterChanged: (f) => setState(() => _filter = f),
                    onSearchChanged: (_) => setState(() {}),
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
                  const SizedBox(height: 14),
                  _StudyNearMeBanner(
                    loading: _studyNearMeCtrl.loading,
                    onPressed: _onStudyNearMe,
                    primary: primary,
                  ),
                  const SizedBox(height: 12),
                  _ExploreStatsStrip(
                    placeCount: displayPlaceCount,
                    docCount: displayDocCount,
                    showingSaved: _showingSaved,
                    primary: primary,
                  ),
                  const SizedBox(height: 12),
                  _ExploreActionRow(
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
                        (_trendingPlaces.isNotEmpty || _trendingDocuments.isNotEmpty)) ...[
                      const SizedBox(height: 18),
                      ExploreFeaturedSection(
                        trendingPlaces: _trendingPlaces,
                        trendingDocuments: _trendingDocuments,
                        onPlaceTap: (item) {
                          final id = item['id']?.toString() ?? '';
                          if (id.isNotEmpty) context.push('/places/$id');
                        },
                        onDocumentTap: (item) {
                          final id = item['id']?.toString() ?? '';
                          if (id.isNotEmpty) context.push('/document/$id');
                        },
                      ),
                    ],
                    if (!_loadingExploreMeta && _weeklyDays.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      ExploreWeeklyChart(
                        days: _weeklyDays,
                        totalPlaces: _weeklyTotalPlaces,
                        totalDownloads: _weeklyTotalDownloads,
                      ),
                    ],
                    if (!_loadingExploreMeta && _topUsers.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      ExploreTopUsersSection(
                        users: _topUsers,
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
                  const SizedBox(height: 18),
                  _ExploreFeedSectionHeader(
                    title: sectionTitle,
                    count: visible.length,
                    showingSaved: _showingSaved,
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
                  const SizedBox(height: 12),
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
                    final item = visible[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < visible.length - 1 ? 10 : 0),
                      child: _ExploreFeedCard(
                        title: item['title']?.toString() ?? '',
                        isPlace: _isPlace(item),
                        onTap: () => _openItem(item),
                        primary: primary,
                      ),
                    );
                  },
                  childCount: visible.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExploreFeedSectionHeader extends StatelessWidget {
  const _ExploreFeedSectionHeader({
    required this.title,
    required this.count,
    required this.showingSaved,
  });

  final String title;
  final int count;
  final bool showingSaved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.title(context),
              ),
        ),
        if (showingSaved) ...[
          const SizedBox(width: 6),
          Icon(Icons.bookmark_rounded, size: 16, color: AppColors.muted(context)),
        ],
        const Spacer(),
        if (count > 0)
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted(context),
            ),
          ),
      ],
    );
  }
}

class _ExploreStatsStrip extends StatelessWidget {
  const _ExploreStatsStrip({
    required this.placeCount,
    required this.docCount,
    required this.showingSaved,
    required this.primary,
  });

  final int placeCount;
  final int docCount;
  final bool showingSaved;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = AppColors.muted(context);

    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 13, color: muted, height: 1.4),
        children: [
          TextSpan(
            text: '$placeCount',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: showingSaved ? muted : AppColors.secondary,
            ),
          ),
          TextSpan(text: ' ${l10n.places}'),
          const TextSpan(text: '  ·  '),
          TextSpan(
            text: '$docCount',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.title(context),
            ),
          ),
          TextSpan(text: ' ${l10n.documents}'),
        ],
      ),
    );
  }
}

class _ExploreActionRow extends StatelessWidget {
  const _ExploreActionRow({
    required this.savedLabel,
    required this.savedSelected,
    required this.onSaved,
    required this.onCreate,
    required this.primary,
  });

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
        Expanded(
          child: _MinimalActionTile(
            icon: Icons.bookmark_outline_rounded,
            label: savedLabel,
            selected: savedSelected,
            accent: primary,
            onTap: onSaved,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MinimalActionTile(
            icon: Icons.add_rounded,
            label: l10n.share,
            accent: primary,
            onTap: onCreate,
          ),
        ),
      ],
    );
  }
}

class _MinimalActionTile extends StatelessWidget {
  const _MinimalActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.45) : AppColors.border(context),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? accent : AppColors.muted(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? accent : AppColors.title(context),
                  ),
                ),
              ),
            ],
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

class _StudyNearMeBanner extends StatelessWidget {
  const _StudyNearMeBanner({
    required this.loading,
    required this.onPressed,
    required this.primary,
  });

  final bool loading;
  final VoidCallback? onPressed;
  final Color primary;

  static const _accent = AppColors.secondary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2A1A12), const Color(0xFF1A1A1A)]
                  : [const Color(0xFFFFF7ED), Colors.white],
            ),
            border: Border.all(color: _accent.withValues(alpha: isDark ? 0.35 : 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, Color(0xFFE65100)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.near_me_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.studyNearMe,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.title(context),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.places,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted(context)),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreFeedCard extends StatelessWidget {
  const _ExploreFeedCard({
    required this.title,
    required this.isPlace,
    required this.onTap,
    required this.primary,
  });

  final String title;
  final bool isPlace;
  final VoidCallback onTap;
  final Color primary;

  static const _accent = AppColors.secondary;
  static const _accentDeep = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = isPlace ? l10n.places : l10n.documents;
    final isDark = AppColors.isDark(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [const Color(0xFF2A1A12), const Color(0xFF1A1A1A)]
                  : [const Color(0xFFFFF7ED), Colors.white],
            ),
            border: Border.all(
              color: _accent.withValues(alpha: isDark ? 0.3 : 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPlace
                          ? [_accent, _accentDeep]
                          : [_accent.withValues(alpha: 0.85), const Color(0xFFFF8A50)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPlace ? Icons.location_on_rounded : Icons.article_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.35,
                          color: AppColors.title(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _accentDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted(context)),
              ],
            ),
          ),
        ),
      ),
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
        Container(height: 40, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 14),
        Container(height: 66, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(14))),
        const SizedBox(height: 12),
        Container(height: 14, width: 200, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Container(height: 48, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(12)))),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 48, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(12)))),
          ],
        ),
        const SizedBox(height: 24),
        Container(height: 16, width: 80, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 12),
        ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 64,
                decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(12)),
              ),
            )),
      ],
    );
  }
}
