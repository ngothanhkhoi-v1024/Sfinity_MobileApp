import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../document/presentation/widgets/document_card.dart';
import '../../../../shared/widgets/voice_search_suffix.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _hasSearched = false;

  List<String> _recentSearches = [];
  List<Map<String, dynamic>> _recommendations = [];
  List<String> _lookupSuggestions = [];
  List<String> _subjectCodes = [];
  bool _loadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(() {
      if (_query.text.trim().isEmpty) {
        setState(() {
          _hasSearched = false;
          _results = [];
        });
      } else {
        setState(() {});
      }
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
    if (!mounted) return;
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearch(String q) async {
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_searches') ?? [];
    list.remove(q);
    list.insert(0, q);
    if (list.length > 5) list.removeLast();
    await prefs.setStringList('recent_searches', list);
    if (!mounted) return;
    setState(() => _recentSearches = list);
  }

  Future<void> _deleteSearch(String q) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_searches') ?? [];
    list.remove(q);
    await prefs.setStringList('recent_searches', list);
    if (!mounted) return;
    setState(() => _recentSearches = list);
  }

  Future<void> _clearAllRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    if (!mounted) return;
    setState(() => _recentSearches = []);
  }

  String? _fileNameFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      final path = Uri.parse(url).path;
      final name = Uri.decodeComponent(path.split('/').last);
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  List<String> _buildLookupSuggestions(List<dynamic> items) {
    final suggestions = <String>{};
    for (final raw in items) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);

      final title = item['title']?.toString().trim();
      if (title != null && title.isNotEmpty && title.length <= 32) {
        suggestions.add(title);
      }

      final category = item['category'];
      if (category is Map && category['name'] != null) {
        final name = category['name'].toString().trim();
        if (name.isNotEmpty) suggestions.add(name);
      }

      final fileName = _fileNameFromUrl(item['fileUrl']?.toString());
      if (fileName != null && !fileName.startsWith('scaled_')) {
        final base = fileName.contains('.') ? fileName.split('.').first : fileName;
        if (base.length >= 3 && base.length <= 24) {
          suggestions.add(base);
        }
      }
    }
    return suggestions.take(6).toList();
  }

  List<String> _buildSubjectCodes(List<dynamic> items) {
    final codes = <String>{};
    for (final raw in items) {
      if (raw is! Map) continue;
      final code = raw['subjectCode']?.toString().trim();
      if (code != null && code.isNotEmpty) {
        codes.add(code.toUpperCase());
      }
    }
    final sorted = codes.toList()..sort();
    return sorted.take(12).toList();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loadingRecommendations = true);
    try {
      final res = await ApiClient.instance.get('/document', query: {
        'publishedOnly': 'true',
        'limit': '40',
      });
      final items = (res['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() {
        _recommendations = items.take(6).toList();
        _lookupSuggestions = _buildLookupSuggestions(items);
        _subjectCodes = _buildSubjectCodes(items);
      });
    } catch (_) {
      // Silent catch
    } finally {
      if (mounted) setState(() => _loadingRecommendations = false);
    }
  }

  bool _isPlace(Map<String, dynamic> item) {
    if (item['type']?.toString() == 'place') return true;
    final body = item['body']?.toString() ?? '';
    return body.contains('type:place');
  }

  String _placeSubtitle(Map<String, dynamic> item) {
    final address = item['address']?.toString().trim();
    if (address != null && address.isNotEmpty) return address;
    return '';
  }

  Widget _buildLookupItem(Map<String, dynamic> item) {
    if (_isPlace(item)) {
      return _PlaceLookupTile(
        item: item,
        subtitle: _placeSubtitle(item),
        onTap: () => _openResult(item),
      );
    }

    return DocumentCard(
      item: item,
      onTap: () => _openResult(item),
    );
  }

  Future<void> _searchBySubject(String subjectCode) async {
    _query.text = subjectCode;
    _query.selection = TextSelection.fromPosition(TextPosition(offset: subjectCode.length));
    await _saveSearch(subjectCode);
    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      final res = await ApiClient.instance.get('/document', query: {
        'subjectCode': subjectCode,
        'publishedOnly': 'true',
        'limit': '20',
      });
      final docs = (res['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => {...Map<String, dynamic>.from(e), 'type': 'document'})
          .toList();
      if (!mounted) return;
      setState(() => _results = docs);
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search({String? customQuery}) async {
    final q = customQuery ?? _query.text.trim();
    if (q.isEmpty) return;

    if (customQuery != null) {
      _query.text = q;
      _query.selection = TextSelection.fromPosition(TextPosition(offset: q.length));
    }

    await _saveSearch(q);
    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      final responses = await Future.wait([
        ApiClient.instance.get('/document', query: {
          'search': q,
          'publishedOnly': 'true',
          'limit': '20',
        }),
        ApiClient.instance.get('/places', query: {
          'search': q,
          'publishedOnly': 'true',
          'limit': '20',
        }),
      ]);

      final docs = (responses[0]['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => {...Map<String, dynamic>.from(e), 'type': 'document'})
          .toList();
      final places = (responses[1]['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => {...Map<String, dynamic>.from(e), 'type': 'place'})
          .toList();

      if (!mounted) return;
      setState(() => _results = [...docs, ...places]);
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openResult(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    context.push(_isPlace(item) ? '/places/$id' : '/document/$id');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = AppColors.primaryOf(context);
    final isQueryEmpty = _query.text.trim().isEmpty;
    final showSuggestions = isQueryEmpty && !_loading && !_hasSearched;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.quickLookup,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.searchFill(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: TextField(
                controller: _query,
                decoration: InputDecoration(
                  hintText: l10n.quickLookupHint,
                  prefixIcon: Icon(Icons.manage_search_rounded, color: AppColors.muted(context)),
                  suffixIcon: VoiceSearchSuffix(
                    controller: _query,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (text) => _search(customQuery: text),
                    onClear: () {
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                      });
                    },
                  ),
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
                ? _buildSuggestions(l10n, primary)
                : _buildSearchResults(l10n, primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(AppLocalizations l10n, Color primary) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentLookups,
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
                child: Text(l10n.clearAll, style: TextStyle(fontSize: 12, color: primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: AppColors.panel(context),
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
        if (_lookupSuggestions.isNotEmpty) ...[
          Text(
            l10n.lookupSuggestions,
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
            children: _lookupSuggestions.map((label) {
              return ActionChip(
                backgroundColor: AppColors.chipBg(context),
                side: BorderSide(color: AppColors.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                label: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.title(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                onPressed: () => _search(customQuery: label),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (_subjectCodes.isNotEmpty) ...[
          Text(
            l10n.lookupBySubject,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.title(context),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _subjectCodes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final code = _subjectCodes[index];
                return ActionChip(
                  backgroundColor: primary.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.1),
                  side: BorderSide(color: primary.withValues(alpha: 0.25)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  label: Text(
                    code,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                  onPressed: () => _searchBySubject(code),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          l10n.recommendedForYou,
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
              child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ),
          )
        else if (_recommendations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                l10n.noRecommendations,
                style: TextStyle(color: AppColors.muted(context), fontSize: 13),
              ),
            ),
          )
        else
          ..._recommendations.map(
            (item) => _buildLookupItem(item),
          ),
      ],
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n, Color primary) {
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search_rounded, size: 48, color: AppColors.muted(context)),
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
              l10n.tryDifferentLookup,
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, i) => _buildLookupItem(_results[i]),
    );
  }
}

class _PlaceLookupTile extends StatelessWidget {
  const _PlaceLookupTile({
    required this.item,
    required this.subtitle,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? '';
    const accentColor = Color(0xFFEF4444);
    final isDark = AppColors.isDark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 118,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Icon(Icons.place_rounded, color: accentColor, size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        height: 1.18,
                        color: AppColors.title(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.chipBg(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.l10n.studyPlaceLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted(context),
                        ),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.muted(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted(context), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
