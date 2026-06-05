import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/document_list_controller.dart';
import '../widgets/document_card.dart';
import '../widgets/document_empty_state.dart';
import '../widgets/document_list_skeleton.dart';
import '../widgets/document_top_panel.dart';

class DocumentListPage extends StatefulWidget {
  const DocumentListPage({super.key, this.embedded = false});

  /// Khi true: không bọc Scaffold (dùng trong shell tab Tài liệu).
  final bool embedded;

  @override
  State<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> {
  late final DocumentListController _controller;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _controller = DocumentListController();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: AppColors.primaryOf(context),
      onRefresh: _controller.load,
      child: _controller.filteredItems.isEmpty
          ? DocumentEmptyState(
              hasSearchQuery: _controller.searchQuery.isNotEmpty,
              onClearSearch: _controller.clearSearch,
              onPrimaryAction: () => context.push(
                RouteNames.documentCreate,
                extra: const {'contentType': 'document'},
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: _controller.filteredItems.length,
              itemBuilder: (context, i) {
                final item = _controller.filteredItems[i] as Map<String, dynamic>;
                return DocumentCard(
                  item: item,
                  showStatus: !_controller.communityMode,
                  onTap: () => context.push('/document/${item['id']}'),
                );
              },
            ),
    );
  }

  Widget _buildContent() {
    if (_controller.loading) {
      return const DocumentListSkeleton();
    }
    if (_controller.error != null) {
      return ErrorView(message: _controller.error!, onRetry: _controller.load);
    }
    return _buildList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (widget.embedded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DocumentTopPanel(
                  embedded: true,
                  communityMode: _controller.communityMode,
                  onModeChanged: _controller.setCommunityMode,
                  searchController: _controller.searchController,
                  onSearchChanged: _controller.updateSearchQuery,
                  categories: _controller.categories,
                  selectedCategory: _controller.selectedCategory,
                  onCategorySelected: _controller.changeCategory,
                  showFilters: _showFilters,
                  onToggleFilters: () => setState(() => _showFilters = !_showFilters),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: _buildContent()),
            ],
          );
        }

        final l10n = context.l10n;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: AppColors.scaffold(context),
          appBar: AppBar(
            title: Text(
              l10n.documents,
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Tooltip(
                  message: l10n.uploadDocument,
                  child: Material(
                    color: Colors.transparent,
                    child: Ink(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOf(context).withValues(
                          alpha: isDark ? 0.22 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryOf(context).withValues(
                            alpha: isDark ? 0.24 : 0.18,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.16 : 0.04,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push(
                          RouteNames.documentCreate,
                          extra: const {'contentType': 'document'},
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add_rounded,
                            color: AppColors.primaryOf(context),
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: DocumentTopPanel(
                  communityMode: _controller.communityMode,
                  onModeChanged: _controller.setCommunityMode,
                  searchController: _controller.searchController,
                  onSearchChanged: _controller.updateSearchQuery,
                  categories: _controller.categories,
                  selectedCategory: _controller.selectedCategory,
                  onCategorySelected: _controller.changeCategory,
                  showFilters: _showFilters,
                  onToggleFilters: () => setState(() => _showFilters = !_showFilters),
                ),
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        );
      },
    );
  }
}
