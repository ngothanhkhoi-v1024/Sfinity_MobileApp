import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:sfinity/features/document/presentation/pages/pdf_full_screen_page.dart';
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
  String _selectedCategory = 'Tất cả';
  String _searchQuery = '';
  String _selectedMemberId = 'all';
  final _searchController = TextEditingController();

  final List<String> _categories = ['Tất cả', 'Tài liệu', 'Hình ảnh', 'Tập tin', 'Địa điểm'];

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

  @override
  Widget build(BuildContext context) {
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
            return Center(child: Text('Lỗi: ${snap.error}'));
          }

          final allResources = snap.data ?? [];
          
          // Filter resources locally based on selected category, search query & member selection
          final filteredResources = allResources.where((msg) {
            // Category filter
            if (_selectedCategory != 'Tất cả') {
              if (_selectedCategory == 'Tài liệu' && msg.type != MessageType.document) return false;
              if (_selectedCategory == 'Địa điểm' && msg.type != MessageType.location) return false;
              if (_selectedCategory == 'Tập tin' && msg.type != MessageType.file) return false;
              if (_selectedCategory == 'Hình ảnh' && msg.type != MessageType.image) return false;
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
                      'Kho lưu trữ nhóm (${filteredResources.length})',
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
                      hintText: 'Tìm kiếm theo tên file hoặc thành viên đăng...',
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
                          const DropdownMenuItem<String>(
                            value: 'all',
                            child: Row(
                              children: [
                                Icon(Icons.people_alt_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Tất cả thành viên', style: TextStyle(fontWeight: FontWeight.w500)),
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
                        const DropdownMenuItem<String>(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.people_alt_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Tất cả thành viên'),
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
                              _selectedCategory == 'Địa điểm'
                                  ? Icons.place_rounded
                                  : _selectedCategory == 'Hình ảnh'
                                      ? Icons.image_rounded
                                      : Icons.folder_open_rounded,
                              size: 64,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy tài nguyên nào',
                              style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Thử thay đổi từ khóa tìm kiếm khác.'
                                  : 'Hãy chia sẻ các tài nguyên bổ ích vào nhóm chat nhé!',
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
                            return _ImageResourceItem(message: msg);
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
                            final title = msg.fileName ?? 'Vị trí địa lý';
                            final subtitle = 'Địa điểm chia sẻ • Gửi bởi ${msg.senderName}';
                            final leading = Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.place_rounded, color: Colors.green.shade700),
                            );
                            final onTap = () async {
                              final placeId = msg.sharedPlaceId;
                              if (placeId != null && placeId.isNotEmpty) {
                                context.push('/places/$placeId');
                              } else if (msg.fileUrl != null && msg.fileUrl!.isNotEmpty) {
                                final uri = Uri.parse(msg.fileUrl!);
                                try {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (_) {}
                              }
                            };

                            return Card(
                              elevation: 0,
                              color: cs.surfaceContainerLowest,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: onTap,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      leading,
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              subtitle,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: cs.onSurfaceVariant,
                                                fontSize: 11,
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
                                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatDate(msg.createdAt),
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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

class _ImageResourceItem extends StatelessWidget {
  const _ImageResourceItem({required this.message});
  final GroupMessageModel message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final imageUrl = message.fileUrl ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              if (imageUrl.isNotEmpty) {
                final uri = Uri.parse(imageUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: cs.surfaceContainerHigh,
                width: 180,
                height: 120,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_rounded, size: 36),
                        ),
                      )
                    : const Center(child: Icon(Icons.image_rounded, size: 36)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${message.fileName ?? "Hình ảnh"} • Đăng bởi ${message.senderName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
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
            content: Text('Đã tải xong: ${widget.message.fileName}'),
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
            content: Text('Tải file thất bại: $e'),
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
      title = msg.sharedDocumentTitle ?? 'Tài liệu không tên';
      subtitle = 'Tài liệu học tập • Chia sẻ bởi ${msg.senderName}';
      leading = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red.shade700),
      );
    } else {
      title = msg.fileName ?? 'Tệp đính kèm';
      final sizeStr = widget.formatSize(msg.fileSize);
      subtitle = '${sizeStr.isNotEmpty ? "$sizeStr • " : ""}Tập tin • Gửi bởi ${msg.senderName}';
      final extColor = _colorForFile(title);
      leading = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: extColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_iconForFile(title), color: extColor.withValues(alpha: 0.9)),
      );
    }

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                          title: msg.fileName ?? 'Tài liệu',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Không thể mở tệp tin PDF: $e'),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
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
                  // Action indicator: downloading (progress), checked (checkmark), or download button
                  if (isDoc)
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5))
                  else if (_isDownloading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    )
                  else if (_fileExists)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: isDark ? Colors.greenAccent : Colors.green,
                    )
                  else
                    Icon(
                      Icons.download_rounded,
                      size: 18,
                      color: cs.primary.withValues(alpha: 0.8),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    widget.formatDate(msg.createdAt),
                    style: TextStyle(
                      fontSize: 9.5,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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
