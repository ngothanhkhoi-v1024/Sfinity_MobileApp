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

        return Scaffold(
          backgroundColor: AppColors.scaffold(context),
          appBar: AppBar(
            title: Text(
              l10n.documents,
              style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: AppColors.primaryOf(context), size: 26),
                onPressed: () => context.push(
                  RouteNames.documentCreate,
                  extra: const {'contentType': 'document'},
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
