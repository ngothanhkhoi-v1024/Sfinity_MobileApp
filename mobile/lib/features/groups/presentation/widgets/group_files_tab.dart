import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:sfinity/features/document/presentation/pages/pdf_full_screen_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/i18n/app_text.dart';
import '../../data/models/group_message_model.dart';
import '../../data/services/group_chat_service.dart';
import '../../data/models/group_model.dart';

class GroupFilesTab extends StatefulWidget {
  const GroupFilesTab({
    super.key,
    required this.groupId,
    required this.onShareDocument,
    required this.members,
  });

  final String groupId;
  final VoidCallback onShareDocument;
  final List<GroupMemberModel> members;

  @override
  State<GroupFilesTab> createState() => _GroupFilesTabState();
}

class _GroupFilesTabState extends State<GroupFilesTab> {
  final _chatService = GroupChatService();
  String _selectedCategory = '';
  String _searchQuery = '';
  String _selectedMemberId = 'all';
  final _searchController = TextEditingController();

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = context.l10n;
    _categories = [
      l10n.allFiles,
      l10n.documents,
      l10n.images,
      l10n.files,
      l10n.location,
    ];
    if (_selectedCategory.isEmpty) {
      _selectedCategory = l10n.allFiles;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _friendlyDisplayName(String? raw, String fallback) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    var name = raw.trim();
    if (name.startsWith('scaled_')) {
      name = name.substring(7);
    }
    final dotIndex = name.lastIndexOf('.');
    final base = dotIndex > 0 ? name.substring(0, dotIndex) : name;
    final looksLikeUuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(base);
    if (looksLikeUuid || base.length < 2) return fallback;
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0A0A0A) : cs.surface,
      child: StreamBuilder<List<GroupMessageModel>>(
        stream: _chatService.groupResourcesStream(widget.groupId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(l10n.groupChatError(snap.error.toString())));
          }

          final allResources = snap.data ?? [];
          
          // Filter resources locally based on selected category, search query & member selection
          final filteredResources = allResources.where((msg) {
            // Category filter
            if (_selectedCategory != l10n.allFiles) {
              if (_selectedCategory == l10n.documents && msg.type != MessageType.document) return false;
              if (_selectedCategory == l10n.location && msg.type != MessageType.location) return false;
              if (_selectedCategory == l10n.files && msg.type != MessageType.file) return false;
              if (_selectedCategory == l10n.images && msg.type != MessageType.image) return false;
            }

            // Member selection filter
            if (_selectedMemberId != 'all' && msg.senderId != _selectedMemberId) {
              return false;
            }

            // Search query filter (matches file name, document/location title OR member/sender name)
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final titleText = msg.sharedDocumentTitle ?? msg.fileName ?? '';
              final titleMatch = titleText.toLowerCase().contains(query);
              final senderMatch = msg.senderName.toLowerCase().contains(query);
              return titleMatch || senderMatch;
            }
            
            return true;
          }).toList();

          return Column(
            children: [
              // Header chỉ chứa tiêu đề Kho lưu trữ nhóm (Bỏ nút chia sẻ như yêu cầu)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Text(
                      l10n.groupStorage(filteredResources.length),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Thanh Tìm kiếm theo tên tệp hoặc thành viên đăng tải
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchFileByName,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : cs.surfaceContainerHigh.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              // Hộp chọn Lọc theo thành viên (Sổ xuống)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    color: isDark ? const Color(0xFF1E1E1E) : cs.surfaceContainerHigh.withValues(alpha: 0.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMemberId,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : cs.surfaceContainerHigh,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: cs.primary),
                      selectedItemBuilder: (context) {
                        return [
                          DropdownMenuItem<String>(
                            value: 'all',
                            child: Row(
                              children: [
                                const Icon(Icons.people_alt_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(l10n.allMembers, style: const TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          ...widget.members.map((m) {
                            return DropdownMenuItem<String>(
                              value: m.user.id,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: m.user.avatar != null && m.user.avatar!.isNotEmpty
                                        ? NetworkImage(m.user.avatar!)
                                        : null,
                                    child: m.user.avatar == null || m.user.avatar!.isEmpty
                                        ? Text(m.user.name.isNotEmpty ? m.user.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    m.user.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ];
                      },
                      items: [
                        DropdownMenuItem<String>(
                          value: 'all',
                          child: Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.allMembers),
                            ],
                          ),
                        ),
                        ...widget.members.map((m) {
                          return DropdownMenuItem<String>(
                            value: m.user.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundImage: m.user.avatar != null && m.user.avatar!.isNotEmpty
                                      ? NetworkImage(m.user.avatar!)
                                      : null,
                                  child: m.user.avatar == null || m.user.avatar!.isEmpty
                                      ? Text(m.user.name.isNotEmpty ? m.user.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(m.user.name),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedMemberId = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),


              // Bộ lọc danh mục (Pills Selector)
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, idx) {
                    final cat = _categories[idx];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                        labelStyle: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : cs.onSurfaceVariant),
                          fontSize: 12.5,
                        ),
                        selectedColor: cs.primary,
                        backgroundColor: isDark ? const Color(0xFF1E1E1E) : cs.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),

              Expanded(
                child: filteredResources.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedCategory == l10n.location
                                  ? Icons.place_rounded
                                  : _selectedCategory == l10n.images
                                      ? Icons.image_rounded
                                      : Icons.folder_open_rounded,
                              size: 64,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noResourceFound,
                              style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? l10n.tryDifferentKeyword
                                  : l10n.shareResources,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredResources.length,
                        itemBuilder: (ctx, i) {
                          final msg = filteredResources[i];

                          // Xử lý riêng dạng Hình ảnh: Hiển thị hình ảnh giống bên chat nhưng nhỏ hơn
                          if (msg.type == MessageType.image) {
                            return _ImageResourceItem(
                              message: msg,
                              formatDate: _formatDate,
                              displayName: _friendlyDisplayName(msg.fileName, l10n.imageLabel),
                            );
                          }

                          // Xử lý Tài liệu học tập và Tệp đính kèm: Cơ chế tải và mở giống bên chat
                          if (msg.type == MessageType.document || msg.type == MessageType.file) {
                            return _FileResourceItem(
                              message: msg,
                              formatDate: _formatDate,
                              formatSize: _formatSize,
                            );
                          }

                          // Xử lý dạng Địa điểm: Hiện dạng thẻ List tiện dụng
                          if (msg.type == MessageType.location) {
                            return _LocationResourceItem(
                              message: msg,
                              formatDate: _formatDate,
                              title: msg.fileName ?? l10n.locationPlaceholder,
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StorageResourceCard extends StatelessWidget {
  const _StorageResourceCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.trailing,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final String date;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: AppColors.card(context),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted(context),
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  trailing,
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationResourceItem extends StatelessWidget {
  const _LocationResourceItem({
    required this.message,
    required this.formatDate,
    required this.title,
  });

  final GroupMessageModel message;
  final String Function(DateTime) formatDate;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = AppColors.isDark(context);
    const accent = Color(0xFF10B981);

    return _StorageResourceCard(
      title: title,
      subtitle: l10n.resourceSharedBy(message.senderName),
      date: formatDate(message.createdAt),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.place_rounded, color: accent, size: 22),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.muted(context),
      ),
      onTap: () async {
        final placeId = message.sharedPlaceId;
        if (placeId != null && placeId.isNotEmpty) {
          context.push('/places/$placeId');
        } else if (message.fileUrl != null && message.fileUrl!.isNotEmpty) {
          final uri = Uri.parse(message.fileUrl!);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {}
        }
      },
    );
  }
}

class _ImageResourceItem extends StatelessWidget {
  const _ImageResourceItem({
    required this.message,
    required this.formatDate,
    required this.displayName,
  });

  final GroupMessageModel message;
  final String Function(DateTime) formatDate;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final imageUrl = message.fileUrl ?? '';
    const accent = Color(0xFF3B82F6);

    return _StorageResourceCard(
      title: displayName,
      subtitle: l10n.resourceSharedBy(message.senderName),
      date: formatDate(message.createdAt),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          color: cs.surfaceContainerHighest,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_rounded,
                    color: accent.withValues(alpha: 0.8),
                  ),
                )
              : Icon(Icons.image_rounded, color: accent.withValues(alpha: 0.8)),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.muted(context),
      ),
      onTap: () async {
        if (imageUrl.isNotEmpty) {
          final uri = Uri.parse(imageUrl);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {}
        }
      },
    );
  }
}

class _FileResourceItem extends StatefulWidget {
  const _FileResourceItem({
    required this.message,
    required this.formatDate,
    required this.formatSize,
  });

  final GroupMessageModel message;
  final String Function(DateTime) formatDate;
  final String Function(int?) formatSize;

  @override
  State<_FileResourceItem> createState() => _FileResourceItemState();
}

class _FileResourceItemState extends State<_FileResourceItem> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _fileExists = false;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    final fileUrl = widget.message.fileUrl;
    if (fileUrl == null || fileUrl.isEmpty) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = widget.message.fileName ?? fileUrl.split('/').last;
      final file = File('${appDir.path}/$fileName');
      final exists = await file.exists();
      if (mounted) {
        setState(() {
          _fileExists = exists;
          _localPath = file.path;
        });
      }
    } catch (e) {
      debugPrint('Error checking file existence: $e');
    }
  }

  Future<void> _downloadFile() async {
    final l10n = context.l10n;
    final fileUrl = widget.message.fileUrl;
    if (fileUrl == null || fileUrl.isEmpty || _localPath == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dio = Dio();
      await dio.download(
        fileUrl,
        _localPath!,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _fileExists = true;
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileUploadedSuccess(widget.message.fileName ?? '')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileUploadFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _iconForFile(String? name) {
    final ext = name?.split('.').lastOrNull?.toLowerCase() ?? '';
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'doc' || 'docx' => Icons.description_rounded,
      'xls' || 'xlsx' => Icons.table_chart_rounded,
      'ppt' || 'pptx' => Icons.slideshow_rounded,
      'zip' || 'rar' => Icons.folder_zip_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  Color _colorForFile(String? name) {
    final ext = name?.split('.').lastOrNull?.toLowerCase() ?? '';
    return switch (ext) {
      'pdf' => Colors.red,
      'doc' || 'docx' => Colors.blue,
      'xls' || 'xlsx' => Colors.green,
      'ppt' || 'pptx' => Colors.orange,
      'zip' || 'rar' => Colors.purple,
      _ => Colors.orange,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final msg = widget.message;

    final isDoc = msg.type == MessageType.document;
    final fileUrl = msg.fileUrl ?? '';

    // Standard card attributes
    Widget leading;
    String title = '';
    String subtitle = '';

    if (isDoc) {
      title = msg.sharedDocumentTitle ?? l10n.untitledDocument;
      subtitle = l10n.resourceSharedBy(msg.senderName);
      leading = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: isDark ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red.shade700, size: 22),
      );
    } else {
      title = _friendlyFileTitle(msg.fileName, l10n.sharedFile);
      final sizeStr = widget.formatSize(msg.fileSize);
      subtitle = '${sizeStr.isNotEmpty ? "$sizeStr • " : ""}${l10n.resourceSharedBy(msg.senderName)}';
      final extColor = _colorForFile(title);
      leading = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: extColor.withValues(alpha: isDark ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_iconForFile(title), color: extColor.withValues(alpha: 0.9), size: 22),
      );
    }

    Widget trailing;
    if (isDoc) {
      trailing = Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted(context));
    } else if (_isDownloading) {
      trailing = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          value: _downloadProgress > 0 ? _downloadProgress : null,
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
        ),
      );
    } else if (_fileExists) {
      trailing = Icon(
        Icons.check_circle_rounded,
        size: 18,
        color: isDark ? Colors.greenAccent : Colors.green,
      );
    } else {
      trailing = Icon(
        Icons.download_rounded,
        size: 18,
        color: cs.primary.withValues(alpha: 0.85),
      );
    }

    return _StorageResourceCard(
      leading: leading,
      title: title,
      subtitle: subtitle,
      date: widget.formatDate(msg.createdAt),
      trailing: trailing,
      onTap: () async {
          if (isDoc) {
            final docId = msg.sharedDocumentId ?? '';
            context.push('/document/$docId');
          } else {
            if (_isDownloading) return;
            if (_fileExists && _localPath != null) {
              final ext = msg.fileName?.split('.').lastOrNull?.toLowerCase() ?? '';
              if (ext == 'pdf') {
                try {
                  final file = File(_localPath!);
                  final bytes = await file.readAsBytes();
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PdfFullScreenPage(
                          pdfBytes: bytes,
                          title: msg.fileName ?? l10n.documentLabel,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.cannotOpenPDF(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                final uri = Uri.parse('file://$_localPath');
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  if (fileUrl.isNotEmpty) {
                    final fallbackUri = Uri.parse(fileUrl);
                    try {
                      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  }
                }
              }
            } else {
              await _downloadFile();
            }
          }
      },
    );
  }

  String _friendlyFileTitle(String? raw, String fallback) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    var name = raw.trim();
    if (name.startsWith('scaled_')) name = name.substring(7);
    final dotIndex = name.lastIndexOf('.');
    final base = dotIndex > 0 ? name.substring(0, dotIndex) : name;
    final looksLikeUuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(base);
    if (looksLikeUuid || base.length < 2) return fallback;
    return name;
  }
}
