import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../features/document/presentation/widgets/document_card.dart';
import '../../../../features/places/presentation/widgets/place_list_tile.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await ApiClient.instance.getList('/favorites');
    } on DioException catch (e) {
      _error = ApiClient.instance.errorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _getFilteredItems(String filterType) {
    return _items.where((fav) {
      final document = fav['document'] as Map<String, dynamic>?;
      if (document == null) return false;

      final type = document['type']?.toString();
      if (filterType == 'document' && type != 'document') return false;
      if (filterType == 'place' && type != 'place') return false;

      if (_searchQuery.isEmpty) return true;

      final title = document['title']?.toString().toLowerCase() ?? '';
      final body = document['body']?.toString().toLowerCase() ?? '';
      final address = document['address']?.toString().toLowerCase() ?? '';
      final zone = document['zone']?.toString().toLowerCase() ?? '';
      final subjectCode = document['subjectCode']?.toString().toLowerCase() ?? '';

      return title.contains(_searchQuery) ||
          body.contains(_searchQuery) ||
          address.contains(_searchQuery) ||
          zone.contains(_searchQuery) ||
          subjectCode.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);
    final primary = AppColors.primaryOf(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            l10n.saved,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.chipBg(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: primary,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.muted(context),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Tất cả'),
                    Tab(text: 'Tài liệu'),
                    Tab(text: 'Địa điểm'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _buildBody(l10n, isDark, primary),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isDark, Color primary) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ErrorView(message: _error!, onRetry: _load),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.searchFill(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14, color: AppColors.title(context)),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trong mục đã lưu...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.muted(context)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
        ),
        
        Expanded(
          child: TabBarView(
            children: [
              _buildTabList('all', l10n, isDark, primary),
              _buildTabList('document', l10n, isDark, primary),
              _buildTabList('place', l10n, isDark, primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabList(String filterType, AppLocalizations l10n, bool isDark, Color primary) {
    final filteredItems = _getFilteredItems(filterType);

    if (filteredItems.isEmpty) {
      return _buildEmptyState(filterType, l10n, primary);
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: filteredItems.length,
        itemBuilder: (context, i) {
          final fav = filteredItems[i] as Map<String, dynamic>;
          final document = fav['document'] as Map<String, dynamic>?;
          if (document == null) return const SizedBox.shrink();

          final docId = document['id']?.toString() ?? '';
          final title = document['title']?.toString() ?? '';
          final isPlace = document['type']?.toString() == 'place';

          final lat = document['latitude'];
          final lng = document['longitude'];
          final LatLng? mapPoint = (lat is num && lng is num) ? LatLng(lat.toDouble(), lng.toDouble()) : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: ValueKey(fav['id'] ?? docId),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
              ),
              confirmDismiss: (direction) async {
                return true;
              },
              onDismissed: (direction) {
                final removedFav = fav;
                final originalIndex = _items.indexOf(fav);
                
                setState(() {
                  _items.removeAt(originalIndex);
                });

                bool undone = false;
                final messenger = ScaffoldMessenger.of(context);
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(isPlace ? 'Đã bỏ lưu địa điểm "$title"' : 'Đã bỏ lưu tài liệu "$title"'),
                    action: SnackBarAction(
                      label: 'HOÀN TÁC',
                      onPressed: () {
                        undone = true;
                        setState(() {
                          _items.insert(originalIndex, removedFav);
                        });
                      },
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                ).closed.then((reason) async {
                  if (!undone) {
                    try {
                      await ApiClient.instance.delete('/favorites/$docId');
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Không thể bỏ lưu: $e')),
                        );
                        setState(() {
                          _items.insert(originalIndex, removedFav);
                        });
                      }
                    }
                  }
                });
              },
              child: isPlace
                  ? PlaceListTile(
                      title: title,
                      subtitle: document['address']?.toString() ?? 'Không có địa chỉ',
                      distanceLabel: document['zone']?.toString() ?? 'Địa điểm',
                      isCommunity: true,
                      isSaved: true,
                      showMiniMap: mapPoint != null,
                      mapPoint: mapPoint,
                      onTap: () => context.push('/places/$docId'),
                    )
                  : DocumentCard(
                      item: document,
                      onTap: () => context.push('/document/$docId'),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String filterType, AppLocalizations l10n, Color primary) {
    IconData icon;
    String title;
    String subtitle;
    Color iconColor;

    if (filterType == 'document') {
      icon = Icons.menu_book_rounded;
      title = 'Chưa lưu tài liệu nào';
      subtitle = 'Lưu các đề thi, bài giảng hay để ôn tập dễ dàng hơn.';
      iconColor = const Color(0xFF3B82F6);
    } else if (filterType == 'place') {
      icon = Icons.place_rounded;
      title = 'Chưa lưu địa điểm nào';
      subtitle = 'Lưu lại quán cafe, thư viện tự học lý tưởng để xem trên bản đồ.';
      iconColor = const Color(0xFFEF4444);
    } else {
      icon = Icons.bookmark_border_rounded;
      title = l10n.noFavoritesYet;
      subtitle = 'Bạn có thể lưu tài liệu học tập hoặc địa điểm từ màn hình Khám phá hoặc Bản đồ.';
      iconColor = const Color(0xFFF59E0B);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.title(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Khám phá ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
