import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/document_list_controller.dart';
import '../widgets/document_card.dart';
import '../widgets/document_empty_state.dart';
import '../widgets/document_filter_chips.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/document_mode_toggle.dart';

class DocumentListPage extends StatefulWidget {
  const DocumentListPage({super.key, this.embedded = false});

  /// Khi true: không bọc Scaffold (dùng trong shell tab Tài liệu).
  final bool embedded;

  @override
  State<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> {
  late final DocumentListController _controller;

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

  Widget _buildBody() {
    if (_controller.loading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
      );
    }
    if (_controller.error != null) {
      return ErrorView(message: _controller.error!, onRetry: _controller.load);
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: _controller.load,
      child: _controller.filteredItems.isEmpty
          ? DocumentEmptyState(
              hasSearchQuery: _controller.searchQuery.isNotEmpty,
              onClearSearch: _controller.clearSearch,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _controller.filteredItems.length,
              itemBuilder: (context, i) {
                final item = _controller.filteredItems[i] as Map<String, dynamic>;
                return DocumentCard(
                  item: item,
                  onTap: () => context.push('/document/${item['id']}'),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (widget.embedded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocumentModeToggle(
                communityMode: _controller.communityMode,
                onChanged: _controller.setCommunityMode,
              ),
              DocumentSearchBar(
                controller: _controller.searchController,
                onChanged: _controller.updateSearchQuery,
                onClear: _controller.clearSearch,
              ),
              DocumentFilterChips(
                categories: _controller.categories,
                selectedCategory: _controller.selectedCategory,
                onSelected: _controller.changeCategory,
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Tài liệu học tập',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 26),
                onPressed: () => context.push(
                  RouteNames.documentCreate,
                  extra: const {'contentType': 'document'},
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              DocumentModeToggle(
                communityMode: _controller.communityMode,
                onChanged: _controller.setCommunityMode,
              ),
              DocumentSearchBar(
                controller: _controller.searchController,
                onChanged: _controller.updateSearchQuery,
                onClear: _controller.clearSearch,
              ),
              DocumentFilterChips(
                categories: _controller.categories,
                selectedCategory: _controller.selectedCategory,
                onSelected: _controller.changeCategory,
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
    );
  }
}

