import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/document_list_controller.dart';

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

  Widget _buildFilterChips() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _controller.categories.length,
        itemBuilder: (context, index) {
          final category = _controller.categories[index];
          final isSelected = _controller.selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _controller.changeCategory(category);
                }
              },
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _controller.searchController,
        onChanged: _controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Tìm tài liệu, mã môn học, từ khóa...',
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
          suffixIcon: _controller.searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                  onPressed: _controller.clearSearch,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: theme.brightness == Brightness.light ? Colors.grey.shade100 : Colors.grey.shade900,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
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
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: theme.brightness == Brightness.light
                          ? Colors.grey.shade100
                          : Colors.grey.shade900,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _controller.searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.menu_book_rounded,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _controller.searchQuery.isNotEmpty
                            ? 'Không tìm thấy kết quả'
                            : 'Chưa có tài liệu nào',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _controller.searchQuery.isNotEmpty
                            ? 'Không tìm thấy tài liệu phù hợp với từ khóa của bạn. Thử tìm mã môn học hoặc từ khóa khác xem sao!'
                            : 'Hãy là người đầu tiên chia sẻ tài liệu ôn thi hữu ích cho cộng đồng Sfinity ngay hôm nay!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_controller.searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: _controller.clearSearch,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Xóa bộ lọc tìm kiếm'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _controller.filteredItems.length,
              itemBuilder: (context, i) {
                final item = _controller.filteredItems[i] as Map<String, dynamic>;
                final body = item['body']?.toString() ?? '';
                final fileType = (item['fileType']?.toString() ?? 'pdf').toLowerCase();
                final subjectCode = item['subjectCode']?.toString() ?? '';
                final downloads = item['downloadsCount'] ?? 0;
                final author = item['author'] as Map?;
                final authorName = author?['name']?.toString() ?? 'Cộng đồng';

                IconData fileIcon = Icons.article_outlined;
                Color iconColor = theme.colorScheme.primary;
                if (fileType == 'pdf') {
                  fileIcon = Icons.picture_as_pdf;
                  iconColor = const Color(0xFFE53935);
                } else if (fileType == 'docx' || fileType == 'doc') {
                  fileIcon = Icons.description;
                  iconColor = const Color(0xFF1E88E5);
                } else if (fileType == 'link') {
                  fileIcon = Icons.link;
                  iconColor = const Color(0xFF8E24AA);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.brightness == Brightness.light
                          ? Colors.grey.shade200
                          : Colors.grey.shade800,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => context.push('/document/${item['id']}'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(fileIcon, size: 30, color: iconColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (subjectCode.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          subjectCode.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    if (subjectCode.isNotEmpty) const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (item['category'] as Map?)?['name']?.toString() ?? 'Tài liệu',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['title']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  body.split('\n').first,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        authorName,
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.file_download_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$downloads',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
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
              _buildSearchBar(),
              _buildFilterChips(),
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
              _buildSearchBar(),
              _buildFilterChips(),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
    );
  }
}
