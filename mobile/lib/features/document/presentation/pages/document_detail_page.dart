import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/document_detail_controller.dart';

class DocumentDetailPage extends StatefulWidget {
  const DocumentDetailPage({super.key, required this.documentId});

  final String documentId;

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  late final DocumentDetailController _controller;
  bool _isFavorite = false;
  bool _loadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _controller = DocumentDetailController();
    _controller.load(widget.documentId);
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final favs = await ApiClient.instance.get('/favorites');
      final favList = favs as List? ?? [];
      _isFavorite = favList.any((e) => (e as Map)['documentId'] == widget.documentId);
    } catch (_) {}
    if (mounted) {
      setState(() => _loadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await ApiClient.instance.delete('/favorites/${widget.documentId}');
      } else {
        await ApiClient.instance.post('/favorites/${widget.documentId}', {});
      }
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Đã lưu tài liệu này!' : 'Đã hủy lưu tài liệu!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.instance.errorMessage(e))),
        );
      }
    }
  }

  void _share() {
    final title = _controller.document?['title']?.toString() ?? 'Sfinity';
    final fileUrl = _controller.document?['fileUrl']?.toString() ?? '';
    Share.share('Tải tài liệu "$title" trên Sfinity: $fileUrl');
  }

  Future<void> _downloadFile() async {
    if (_controller.document == null) return;
    final fileUrl = _controller.document!['fileUrl']?.toString() ?? '';
    if (fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài liệu này chưa có liên kết tải xuống.')),
      );
      return;
    }

    final success = await _controller.triggerDownload(fileUrl);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mở tài liệu thành công!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else if (_controller.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải tài liệu: ${_controller.error}')),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(1)} ${suffixes[i]}";
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.grey.shade50 : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.brightness == Brightness.light ? Colors.grey.shade200 : Colors.grey.shade800,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.document == null && _controller.error == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết')),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
          );
        }

        if (_controller.error != null && _controller.document == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết')),
            body: ErrorView(
              message: _controller.error!,
              onRetry: () => _controller.load(widget.documentId),
            ),
          );
        }

        final title = _controller.document?['title']?.toString() ?? '';
        final body = _controller.document?['body']?.toString() ?? '';
        final fileType = (_controller.document?['fileType']?.toString() ?? 'pdf').toUpperCase();
        final fileSizeRaw = _controller.document?['fileSize'] ?? 0;
        final fileSize = fileSizeRaw is int ? _formatBytes(fileSizeRaw) : 'Chưa rõ';
        final downloads = _controller.document?['downloadsCount'] ?? 0;
        final subjectCode = _controller.document?['subjectCode']?.toString() ?? 'Chưa có';
        final tags = _controller.document?['tags'] as List? ?? [];
        final category = (_controller.document?['category'] as Map?)?['name']?.toString() ?? 'Tài liệu';

        final systemPrimary = theme.colorScheme.primary;
        final systemSecondary = theme.colorScheme.secondary;

        IconData fileIcon = Icons.article_outlined;
        if (fileType == 'PDF') {
          fileIcon = Icons.picture_as_pdf;
        } else if (fileType == 'DOCX' || fileType == 'DOC') {
          fileIcon = Icons.description;
        } else if (fileType == 'LINK') {
          fileIcon = Icons.cloud_download;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết tài liệu', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(Icons.share_outlined), onPressed: _share),
              if (!_loadingFavorite)
                IconButton(
                  icon: Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border, color: _isFavorite ? systemPrimary : null),
                  onPressed: _toggleFavorite,
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              systemPrimary.withOpacity(0.05),
                              systemSecondary.withOpacity(0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: systemPrimary.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: systemPrimary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(fileIcon, size: 40, color: systemPrimary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category,
                              style: TextStyle(
                                color: systemPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildInfoTile(context, Icons.code, 'MÃ MÔN HỌC', subjectCode.toUpperCase()),
                          _buildInfoTile(context, Icons.insert_drive_file, 'ĐỊNH DẠNG', fileType),
                          _buildInfoTile(context, Icons.data_usage, 'DUNG LƯỢNG', fileSize),
                          _buildInfoTile(context, Icons.file_download, 'LƯỢT TẢI', '$downloads'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Mô tả tài liệu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        body.isNotEmpty ? body : 'Không có mô tả chi tiết cho tài liệu này.',
                        style: const TextStyle(fontSize: 14, height: 1.45),
                      ),
                      const SizedBox(height: 24),

                      if (tags.isNotEmpty) ...[
                        const Text(
                          'Thẻ liên quan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                '#$t',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(
                      top: BorderSide(
                        color: theme.brightness == Brightness.light
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [systemPrimary, systemSecondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ElevatedButton(
                      onPressed: _controller.downloading ? null : _downloadFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _controller.downloading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  fileType == 'LINK' ? Icons.open_in_new : Icons.file_download,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  fileType == 'LINK' ? 'Mở liên kết tài liệu' : 'Tải xuống tài liệu',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
