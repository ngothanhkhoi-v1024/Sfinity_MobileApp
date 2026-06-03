import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../study_near_me/presentation/controllers/study_near_me_controller.dart';
import '../../../study_near_me/presentation/widgets/study_near_me_results_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/explore_top_panel.dart';

/// Tab Khám phá — feed địa điểm & tài liệu.
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

  @override
  void initState() {
    super.initState();
    _studyNearMeCtrl = StudyNearMeController();
    _studyNearMeCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(_onSearchTextChanged);
    _load();
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
        SnackBar(content: Text(_studyNearMeCtrl.error ?? 'Không tìm được kết quả')),
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
    if (_showingSaved) {
      await _loadFavorites();
    } else {
      await _load();
    }
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
    final secondary = theme.colorScheme.secondary;
    final visible = _visibleItems;
    final isSearching = _searchController.text.trim().isNotEmpty;
    final spotlight = _items.take(5).cast<Map<String, dynamic>>().toList();
    final displayPlaceCount = _showingSaved ? _savedPlaceCount : _placeCount;
    final displayDocCount = _showingSaved ? _savedDocCount : _docCount;
    final sectionTitle = _showingSaved
        ? l10n.saved
        : (isSearching ? 'Kết quả' : 'Mới nhất');

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
                    title: l10n.explore,
                    subtitle: 'Địa điểm học tập và tài liệu từ cộng đồng',
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
                            'Đang tìm…',
                            style: TextStyle(fontSize: 12, color: primary),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  _StudyNearMeBanner(
                    loading: _studyNearMeCtrl.loading,
                    onPressed: _onStudyNearMe,
                    primary: primary,
                    secondary: secondary,
                  ),
                  const SizedBox(height: 12),
                  _ExploreStatsStrip(
                    placeCount: displayPlaceCount,
                    docCount: displayDocCount,
                    isDark: isDark,
                    primary: primary,
                    showingSaved: _showingSaved,
                  ),
                  const SizedBox(height: 10),
                  _ExploreActionRow(
                    savedLabel: l10n.saved,
                    savedSelected: _showingSaved,
                    onSaved: _toggleSavedView,
                    onCreate: () => context.push(
                      RouteNames.documentCreate,
                      extra: const {'contentType': 'document'},
                    ),
                  ),
                  if (spotlight.isNotEmpty && !isSearching && !_showingSaved) ...[
                    const SizedBox(height: 14),
                    _ExploreSectionLabel(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Gợi ý cho bạn',
                      primary: primary,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 108,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: spotlight.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final item = spotlight[i];
                          return _SpotlightCard(
                            title: item['title']?.toString() ?? '',
                            isPlace: _isPlace(item),
                            isDark: isDark,
                            onTap: () => _openItem(item),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ExploreFeedSectionHeader(
                    title: sectionTitle,
                    count: visible.length,
                    showingSaved: _showingSaved,
                    primary: primary,
                    isDark: isDark,
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
                child: _ExploreSavedEmptyState(message: l10n.noFavoritesYet, isDark: isDark),
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
                        isDark: isDark,
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

class _ExploreSectionLabel extends StatelessWidget {
  const _ExploreSectionLabel({
    required this.icon,
    required this.title,
    required this.primary,
  });

  final IconData icon;
  final String title;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: primary),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ExploreFeedSectionHeader extends StatelessWidget {
  const _ExploreFeedSectionHeader({
    required this.title,
    required this.count,
    required this.showingSaved,
    required this.primary,
    required this.isDark,
  });

  final String title;
  final int count;
  final bool showingSaved;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
        ),
        if (showingSaved) ...[
          const SizedBox(width: 6),
          const Icon(Icons.bookmark_rounded, size: 18, color: Color(0xFFF59E0B)),
        ],
        const Spacer(),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primary),
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
    required this.isDark,
    required this.primary,
    this.showingSaved = false,
  });

  final int placeCount;
  final int docCount;
  final bool isDark;
  final Color primary;
  final bool showingSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryTint(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
      ),
      child: Row(
        children: [
          _StatPill(icon: Icons.place_rounded, count: placeCount, label: 'địa điểm', color: const Color(0xFFEF4444)),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.border(context),
          ),
          _StatPill(icon: Icons.menu_book_rounded, count: docCount, label: 'tài liệu', color: const Color(0xFF3B82F6)),
          const Spacer(),
          Icon(
            showingSaved ? Icons.bookmark_rounded : Icons.trending_up_rounded,
            size: 18,
            color: showingSaved ? const Color(0xFFF59E0B) : primary.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.muted(context)
                : AppColors.muted(context),
          ),
        ),
      ],
    );
  }
}

class _ExploreActionRow extends StatelessWidget {
  const _ExploreActionRow({
    required this.savedLabel,
    required this.savedSelected,
    required this.onSaved,
    required this.onCreate,
  });

  final String savedLabel;
  final bool savedSelected;
  final VoidCallback onSaved;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientShortcutTile(
            icon: Icons.bookmark_rounded,
            label: savedLabel,
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            selected: savedSelected,
            onTap: onSaved,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientShortcutTile(
            icon: Icons.add_circle_rounded,
            label: 'Đăng bài',
            gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
            onTap: onCreate,
          ),
        ),
      ],
    );
  }
}

class _GradientShortcutTile extends StatelessWidget {
  const _GradientShortcutTile({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            border: selected
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({
    required this.title,
    required this.isPlace,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final bool isPlace;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isPlace ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 148,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPlace ? Icons.place_rounded : Icons.menu_book_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.25),
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
    return Column(
      children: [
        Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade500),
        const SizedBox(height: 8),
        Text('Không tìm thấy "$query"'),
        TextButton(onPressed: onClear, child: const Text('Xóa tìm kiếm')),
      ],
    );
  }
}

class _StudyNearMeBanner extends StatelessWidget {
  const _StudyNearMeBanner({
    required this.loading,
    required this.onPressed,
    required this.primary,
    required this.secondary,
  });

  final bool loading;
  final VoidCallback? onPressed;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, secondary],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Học gần tôi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tìm địa điểm & tài liệu quanh bạn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
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
    required this.isDark,
  });

  final String title;
  final bool isPlace;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = isPlace ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
    final accentBg = accent.withValues(alpha: isDark ? 0.18 : 0.1);
    final label = isPlace ? 'Địa điểm' : 'Tài liệu';

    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPlace ? Icons.place_rounded : Icons.menu_book_rounded,
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
              ),
            ],
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
            'Chưa có bài chia sẻ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Hãy là người đầu tiên đăng địa điểm hoặc tài liệu!',
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
            'Lưu địa điểm hoặc tài liệu từ trang chi tiết để xem tại đây',
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Container(height: 32, width: 140, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 10),
        Container(height: 16, width: 260, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 20),
        Container(height: 52, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(26))),
        const SizedBox(height: 10),
        Container(height: 36, width: 220, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(20))),
        const SizedBox(height: 16),
        Container(height: 84, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(20))),
        const SizedBox(height: 16),
        Container(height: 48, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(14))),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: Container(height: 80, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(16)))),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 80, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(16)))),
          ],
        ),
        const SizedBox(height: 28),
        Container(height: 22, width: 100, decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 12),
        ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 80,
                decoration: BoxDecoration(color: skeleton, borderRadius: BorderRadius.circular(16)),
              ),
            )),
      ],
    );
  }
}
