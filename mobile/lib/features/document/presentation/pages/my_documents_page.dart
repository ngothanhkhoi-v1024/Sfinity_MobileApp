import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bar_add_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../utils/document_state.dart';
import '../widgets/document_list_skeleton.dart';

class MyDocumentsPage extends StatefulWidget {
  const MyDocumentsPage({super.key});

  @override
  State<MyDocumentsPage> createState() => _MyDocumentsPageState();
}

class _MyDocumentsPageState extends State<MyDocumentsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allDocuments = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  // Stats
  int _totalCount = 0;
  int _pendingCount = 0;
  int _publishedCount = 0;
  int _rejectedCount = 0;
  int _privateCount = 0;
  int _hiddenCount = 0;

  final List<String> _statuses = ['ALL', 'PRIVATE', 'PENDING', 'PUBLISHED', 'REJECTED', 'HIDDEN'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentUserId = SfinityApp.auth.user?['id']?.toString();
      final res = await SfinityApp.documentRepository.getDocuments(
        authorId: currentUserId,
        limit: 100,
      );
      _allDocuments = res['items'] as List? ?? [];

      _calculateStats();
    } on DioException catch (e) {
      _error = e.message ?? 'Đã xảy ra lỗi kết nối';
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _calculateStats() {
    _totalCount = _allDocuments.length;
    _pendingCount = 0;
    _publishedCount = 0;
    _rejectedCount = 0;
    _privateCount = 0;
    _hiddenCount = 0;

    for (final doc in _allDocuments) {
      final item = Map<String, dynamic>.from(doc as Map);
      final visibility = documentVisibilityOf(item);
      final moderation = documentModerationStatusOf(item);

      if (visibility == documentVisibilityPrivate) {
        _privateCount++;
      } else if (moderation == documentModerationPending) {
        _pendingCount++;
      } else if (moderation == documentModerationApproved) {
        _publishedCount++;
      } else if (moderation == documentModerationRejected) {
        _rejectedCount++;
      } else if (moderation == documentModerationHidden) {
        _hiddenCount++;
      }
    }
  }

  List<dynamic> _getFilteredDocuments(String status) {
    return _allDocuments.where((doc) {
      final item = Map<String, dynamic>.from(doc as Map);
      final visibility = documentVisibilityOf(item);
      final moderation = documentModerationStatusOf(item);

      final matchesTab = switch (status) {
        'ALL' => true,
        'PRIVATE' => visibility == documentVisibilityPrivate,
        'PENDING' => visibility == documentVisibilityPublic && moderation == documentModerationPending,
        'PUBLISHED' => visibility == documentVisibilityPublic && moderation == documentModerationApproved,
        'REJECTED' => visibility == documentVisibilityPublic && moderation == documentModerationRejected,
        'HIDDEN' => visibility == documentVisibilityPublic && moderation == documentModerationHidden,
        _ => false,
      };

      if (!matchesTab) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final title = (doc['title']?.toString() ?? '').toLowerCase();
        final body = (doc['body']?.toString() ?? '').toLowerCase();
        final subjectCode = (doc['subjectCode']?.toString() ?? '').toLowerCase();
        final category = (doc['category'] as Map?)?['name']?.toString() ?? '';
        
        final matches = title.contains(_searchQuery) ||
            body.contains(_searchQuery) ||
            subjectCode.contains(_searchQuery) ||
            category.toLowerCase().contains(_searchQuery);
        
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _deleteDocument(String id) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 36),
        title: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          l10n.deleteDocumentConfirm,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.cancelBtn2, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await SfinityApp.documentRepository.deleteDocument(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteDocumentSuccess)),
          );
          _loadDocuments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.deleteDocumentFailed}: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(
          l10n.myPosts,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        elevation: 0,
        actions: [
          AppBarAddButton(
            tooltip: l10n.uploadDocument,
            onPressed: () async {
              await context.push(
                RouteNames.documentCreate,
                extra: const {'contentType': 'document'},
              );
              _loadDocuments();
            },
          ),
        ],
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: DocumentListSkeleton(),
            )
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadDocuments)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatsDashboard(primary),
                          const SizedBox(height: 12),
                          // Modern Search Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: AppColors.panel(context, radius: 12),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                icon: Icon(Icons.search, color: AppColors.muted(context), size: 20),
                                hintText: 'Tìm kiếm tài liệu học tập...',
                                hintStyle: TextStyle(fontSize: 14, color: AppColors.muted(context)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () => _searchController.clear(),
                                        child: Icon(Icons.close, color: AppColors.muted(context), size: 18),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: _statuses.map((status) {
                          final docs = _getFilteredDocuments(status);
                          return RefreshIndicator(
                            color: primary,
                            onRefresh: _loadDocuments,
                            child: docs.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {
                                      final doc = docs[index] as Map<String, dynamic>;
                                      return _MyDocumentCard(
                                        doc: doc,
                                        primary: primary,
                                        onTap: () async {
                                          await context.push('/document/${doc['id']}');
                                          _loadDocuments();
                                        },
                                        onEdit: () async {
                                          await context.push('/document/${doc['id']}/edit');
                                          _loadDocuments();
                                        },
                                        onDelete: () => _deleteDocument(doc['id'].toString()),
                                      );
                                    },
                                  ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.folder_open_rounded, size: 48, color: AppColors.muted(context)),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noDocumentsFound,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.subtitle(context)),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.yourDocumentsHere,
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsDashboard(Color primary) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatItem(
            title: l10n.documents,
            value: '$_totalCount',
            icon: Icons.article_rounded,
            color: primary,
            isSelected: _tabController.index == 0,
            onTap: () => _tabController.animateTo(0),
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            title: l10n.onlyMe,
            value: '$_privateCount',
            icon: Icons.lock_outline_rounded,
            color: Colors.orange.shade700,
            isSelected: _tabController.index == 1,
            onTap: () => _tabController.animateTo(1),
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            title: l10n.statusPending,
            value: '$_pendingCount',
            icon: Icons.hourglass_empty_rounded,
            color: Colors.blue.shade700,
            isSelected: _tabController.index == 2,
            onTap: () => _tabController.animateTo(2),
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            title: l10n.statusPublished,
            value: '$_publishedCount',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green.shade700,
            isSelected: _tabController.index == 3,
            onTap: () => _tabController.animateTo(3),
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            title: l10n.statusRejected,
            value: '$_rejectedCount',
            icon: Icons.cancel_outlined,
            color: Colors.red.shade700,
            isSelected: _tabController.index == 4,
            onTap: () => _tabController.animateTo(4),
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            title: l10n.statusHidden,
            value: '$_hiddenCount',
            icon: Icons.visibility_off_outlined,
            color: Colors.grey.shade700,
            isSelected: _tabController.index == 5,
            onTap: () => _tabController.animateTo(5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    
    final cardBgColor = isSelected 
        ? color 
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    
    final textColor = isSelected 
        ? Colors.white 
        : (isDark ? Colors.white : Colors.grey[900]);
        
    final subtitleColor = isSelected
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.muted(context);
        
    final iconColor = isSelected ? Colors.white : color;

    return Material(
      color: cardBgColor,
      borderRadius: BorderRadius.circular(14),
      elevation: isSelected ? 4 : 0,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 86,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : color.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyDocumentCard extends StatelessWidget {
  const _MyDocumentCard({
    required this.doc,
    required this.primary,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> doc;
  final Color primary;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final title = doc['title']?.toString() ?? '';
    final body = doc['body']?.toString() ?? '';
    final fileType = (doc['fileType']?.toString() ?? 'pdf').toLowerCase();
    final subjectCode = doc['subjectCode']?.toString() ?? '';
    final downloads = doc['downloadsCount'] ?? 0;
    final visibility = documentVisibilityOf(doc);
    final moderation = documentModerationStatusOf(doc);

    final (fileIcon, iconColor) = _resolveFileIcon(fileType, theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppColors.panel(context, radius: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File Type Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(fileIcon, size: 28, color: iconColor),
                ),
                const SizedBox(width: 12),
                // Core Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (subjectCode.isNotEmpty) ...[
                            _Badge(
                              text: subjectCode.toUpperCase(),
                              color: primary,
                              bgOpacity: 0.08,
                            ),
                            const SizedBox(width: 6),
                          ],
                          _Badge(
                            text:   l10n.translateCategory(
                              (doc['category'] as Map?)?['name']?.toString() ?? 'Tài liệu',
                            ),
                            color: AppColors.muted(context),
                            backgroundColor: AppColors.chipBg(context),
                          ),
                          const SizedBox(width: 6),
                          // Downloads count tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.file_download_outlined, size: 10, color: Color(0xFF10B981)),
                                const SizedBox(width: 2),
                                Text(
                                  '$downloads',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _buildStatusBadge(context, visibility, moderation),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (body.isNotEmpty)
                        Text(
                          body.split('\n').first,
                          style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Card Actions Dropdown
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: AppColors.muted(context), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 100),
                  onSelected: (val) {
                    if (val == 'edit') {
                      onEdit();
                    } else if (val == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Sửa', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(fontSize: 13, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String visibility,
    String moderation,
  ) {
    final l10n = context.l10n;
    if (visibility == documentVisibilityPrivate) {
      return _Badge(
          text: l10n.onlyMe,
          color: Colors.orange,
          bgOpacity: 0.1,
        );
    }

    switch (moderation) {
      case documentModerationPending:
        return _Badge(
          text: l10n.statusPending,
          color: Colors.blue,
          bgOpacity: 0.1,
        );
      case documentModerationRejected:
        return _Badge(
          text: l10n.statusRejected,
          color: Colors.red,
          bgOpacity: 0.1,
        );
      case documentModerationHidden:
        return _Badge(
          text: l10n.statusHidden,
          color: Colors.grey,
          bgOpacity: 0.1,
        );
      case documentModerationApproved:
        return _Badge(
          text: l10n.statusPublished,
          color: Colors.green,
          bgOpacity: 0.1,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  (IconData, Color) _resolveFileIcon(String fileType, ThemeData theme) {
    switch (fileType) {
      case 'pdf':
        return (Icons.picture_as_pdf, AppColors.primary);
      case 'docx':
      case 'doc':
        return (Icons.description, const Color(0xFF1E88E5));
      case 'link':
        return (Icons.link, const Color(0xFF8E24AA));
      default:
        return (Icons.article_outlined, theme.colorScheme.primary);
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    this.backgroundColor,
    this.bgOpacity,
  });

  final String text;
  final Color color;
  final Color? backgroundColor;
  final double? bgOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: bgOpacity ?? 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
