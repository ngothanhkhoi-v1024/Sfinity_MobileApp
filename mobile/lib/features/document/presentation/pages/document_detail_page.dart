import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:intl/intl.dart';

import '../../../../app.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/document_detail_controller.dart';
import '../widgets/document_info_tile.dart';
import '../widgets/document_review_card.dart';
import 'pdf_full_screen_page.dart';

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

  // Star selector, comment field and form state
  bool _showReviewForm = false;
  int _userRating = 5;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _reviewFormKey = GlobalKey();

  // Scroll gestures controller for parent SingleChildScrollView
  bool _parentScrollEnabled = true;

  // State variables for rating filter and comment pagination
  String _selectedRatingFilter = 'Tất cả';
  String _selectedSortOrder = 'Mới nhất';
  int _visibleReviewsCount = 5;
  
  Uint8List? _pdfBytes;
  bool _pdfBytesLoading = false;
  String? _pdfLoadError;

  Future<void> _loadPdfBytes(String url) async {
    if (_pdfBytes != null || _pdfBytesLoading) return;
    setState(() {
      _pdfBytesLoading = true;
      _pdfLoadError = null;
    });

    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        setState(() {
          _pdfBytes = Uint8List.fromList(response.data!);
          _pdfBytesLoading = false;
        });
      } else {
        setState(() {
          _pdfLoadError = 'Không thể tải tệp tài liệu PDF';
          _pdfBytesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _pdfLoadError = 'Không thể kết nối đến máy chủ: $e';
        _pdfBytesLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = DocumentDetailController();
    _controller.load(widget.documentId);
    _checkFavorite();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkFavorite() async {
    try {
      // Use getList instead of get to correctly fetch the raw JSON array of favorites
      final favs = await ApiClient.instance.getList('/favorites');
      _isFavorite = favs.any((e) => (e as Map)['documentId'] == widget.documentId);
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
      if (!mounted) return;
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

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài liệu'),
        content: const Text('Bạn có chắc chắn muốn xóa tài liệu này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        setState(() {
          _pdfBytes = null;
        });
        await SfinityApp.documentRepository.deleteDocument(docId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa tài liệu thành công')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xóa tài liệu thất bại: $e')),
          );
        }
      }
    }
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
    if (!mounted) return;
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

  Future<void> _submitReview() async {
    if (_userRating < 1 || _userRating > 5) return;

    final success = await _controller.submitReview(
      widget.documentId,
      _userRating,
      _commentController.text,
    );

    if (!mounted) return;
    if (success) {
      _commentController.clear();
      setState(() {
        _userRating = 5;
        _showReviewForm = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đánh giá tài liệu thành công!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else if (_controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi đánh giá thất bại: ${_controller.error}')),
      );
    }
  }

  Future<void> _deleteMyReview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa đánh giá'),
        content: const Text('Bạn có chắc chắn muốn xóa nhận xét và điểm đánh giá của mình không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      final success = await _controller.deleteReview(widget.documentId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa đánh giá của bạn.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else if (_controller.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa đánh giá: ${_controller.error}')),
        );
      }
    }
  }

  void _startEditReview(int rating, String comment) {
    setState(() {
      _userRating = rating;
      _commentController.text = comment;
      _showReviewForm = true;
    });

    // Auto-scroll to review form
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _reviewFormKey.currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final currentUserId = SfinityApp.auth.user?['id']?.toString();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.document == null && _controller.error == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết')),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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

        final doc = _controller.document!;
        final title = doc['title']?.toString() ?? '';
        final body = doc['body']?.toString() ?? '';
        final fileType = (doc['fileType']?.toString() ?? 'pdf').toUpperCase();
        final fileSizeRaw = doc['fileSize'] ?? 0;
        final fileSize = fileSizeRaw is int ? _formatBytes(fileSizeRaw) : 'Chưa rõ';
        final downloads = doc['downloadsCount'] ?? 0;
        final subjectCode = doc['subjectCode']?.toString() ?? 'Chưa có';
        final tags = doc['tags'] as List? ?? [];
        final category = (doc['category'] as Map?)?['name']?.toString() ?? 'Tài liệu';
        final fileUrl = doc['fileUrl']?.toString() ?? '';
        final isAuthor = doc['authorId']?.toString() == currentUserId;

        if (fileUrl.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadPdfBytes(fileUrl);
          });
        }
        
        // Phân tách nhận xét cá nhân, nhận xét tác giả và người khác
        final hasMyReview = _controller.reviews.any((e) => (e as Map)['userId'] == currentUserId);
        final myReview = _controller.reviews.firstWhere(
          (e) => (e as Map)['userId'] == currentUserId,
          orElse: () => null,
        ) as Map<String, dynamic>?;

        final otherReviews = _controller.reviews.where(
          (e) => (e as Map)['userId'] != currentUserId,
        ).toList();

        final authorReview = otherReviews.firstWhere(
          (e) => (e as Map)['userId'] == doc['authorId'],
          orElse: () => null,
        ) as Map<String, dynamic>?;

        final remainingReviews = otherReviews.where(
          (e) => (e as Map)['userId'] != doc['authorId'],
        ).toList();

        // Ghim nhận xét của tác giả lên đầu danh sách cộng đồng
        final publicReviews = [
          if (authorReview != null) authorReview,
          ...remainingReviews,
        ];

        // Lọc danh sách nhận xét cộng đồng theo số sao đã chọn
        final filteredReviews = publicReviews.where((rev) {
          if (_selectedRatingFilter == 'Tất cả') return true;
          final rating = (rev['rating'] as num?)?.toInt() ?? 5;
          return '$rating ★' == _selectedRatingFilter;
        }).toList();

        // Sắp xếp danh sách nhận xét cộng đồng theo tùy chọn đã chọn
        filteredReviews.sort((a, b) {
          // Luôn giữ ghim bài viết của Tác giả lên vị trí đầu tiên
          final isAuthorA = a['userId'] == doc['authorId'];
          final isAuthorB = b['userId'] == doc['authorId'];
          if (isAuthorA && !isAuthorB) return -1;
          if (!isAuthorA && isAuthorB) return 1;

          if (_selectedSortOrder == 'Mới nhất') {
            final dateA = a['createdAt'] != null
                ? (a['createdAt'] is DateTime
                    ? a['createdAt'] as DateTime
                    : DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now())
                : DateTime.now();
            final dateB = b['createdAt'] != null
                ? (b['createdAt'] is DateTime
                    ? b['createdAt'] as DateTime
                    : DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now())
                : DateTime.now();
            return dateB.compareTo(dateA); // Mới nhất lên đầu
          } else if (_selectedSortOrder == 'Cũ nhất') {
            final dateA = a['createdAt'] != null
                ? (a['createdAt'] is DateTime
                    ? a['createdAt'] as DateTime
                    : DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now())
                : DateTime.now();
            final dateB = b['createdAt'] != null
                ? (b['createdAt'] is DateTime
                    ? b['createdAt'] as DateTime
                    : DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now())
                : DateTime.now();
            return dateA.compareTo(dateB); // Cũ nhất lên đầu
          } else if (_selectedSortOrder == 'Đánh giá cao nhất') {
            final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
            final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
            return ratingB.compareTo(ratingA); // Đánh giá cao nhất lên đầu
          } else if (_selectedSortOrder == 'Đánh giá thấp nhất') {
            final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
            final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
            return ratingA.compareTo(ratingB); // Đánh giá thấp nhất lên đầu
          }
          return 0;
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết tài liệu', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              // Download Document Button
              IconButton(
                icon: _controller.downloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        fileType == 'LINK' ? Icons.open_in_new : Icons.file_download_outlined,
                      ),
                onPressed: _controller.downloading ? null : _downloadFile,
                tooltip: 'Tải xuống',
              ),
              // Save/Bookmark Button
              if (!_loadingFavorite)
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: _isFavorite ? primaryColor : null,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: _isFavorite ? 'Hủy lưu' : 'Lưu tài liệu',
                ),
              // 3-dots overflow popup menu for edit/delete (only for author)
              if (isAuthor)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        await context.push('/document/${doc['id']}/edit');
                        _controller.load(widget.documentId);
                        break;
                      case 'delete':
                        if (context.mounted) {
                          _confirmDelete(context, doc['id'].toString());
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa tài liệu', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cột trái: Trình đọc PDF toàn bộ chiều cao (chiếm 55%)
                    if (fileUrl.isNotEmpty)
                      Expanded(
                        flex: 11,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                          child: _buildPdfViewer(context, fileUrl, theme),
                        ),
                      ),
                    // Cột phải: Thông tin chi tiết & Bình luận cuộn độc lập (chiếm 45%)
                    Expanded(
                      flex: 9,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(fileUrl.isNotEmpty ? 8 : 16, 12, 16, 32),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, title, category, primaryColor),
                            const SizedBox(height: 16),
                            _buildSpecsGrid(context, subjectCode, fileType, fileSize, downloads),
                            const SizedBox(height: 20),
                            _buildDescription(body),
                            const SizedBox(height: 20),
                            if (tags.isNotEmpty) ...[
                              _buildTags(tags, primaryColor),
                              const SizedBox(height: 20),
                            ],
                            const Divider(),
                            const SizedBox(height: 20),
                            _buildReviewsArea(
                              context: context,
                              primaryColor: primaryColor,
                              theme: theme,
                              currentUserId: currentUserId,
                              doc: doc,
                              hasMyReview: hasMyReview,
                              myReview: myReview,
                              filteredReviews: filteredReviews,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  physics: _parentScrollEnabled
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, title, category, primaryColor),
                      const SizedBox(height: 16),
                      if (fileUrl.isNotEmpty) ...[
                        _buildPdfViewer(context, fileUrl, theme, height: 460),
                        const SizedBox(height: 20),
                      ],
                      _buildSpecsGrid(context, subjectCode, fileType, fileSize, downloads),
                      const SizedBox(height: 24),
                      _buildDescription(body),
                      const SizedBox(height: 24),
                      if (tags.isNotEmpty) ...[
                        _buildTags(tags, primaryColor),
                        const SizedBox(height: 32),
                      ],
                      const Divider(),
                      const SizedBox(height: 24),
                      _buildReviewsArea(
                        context: context,
                        primaryColor: primaryColor,
                        theme: theme,
                        currentUserId: currentUserId,
                        doc: doc,
                        hasMyReview: hasMyReview,
                        myReview: myReview,
                        filteredReviews: filteredReviews,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // --- WIDGET HELPER LAYOUT METHODS ---

  Widget _buildHeader(BuildContext context, String title, String category, Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
          ),
          child: Icon(
            (_controller.document?['fileType']?.toString() ?? 'pdf').toUpperCase() == 'PDF'
                ? Icons.picture_as_pdf
                : Icons.article,
            size: 28,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_controller.avgRating != null) ...[
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '${_controller.avgRating!.toStringAsFixed(1)} (${_controller.reviewCount})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Chưa có đánh giá',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPdfViewer(BuildContext context, String fileUrl, ThemeData theme, {double? height}) {
    if (_pdfBytes != null) {
      return Stack(
        children: [
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Listener(
                onPointerDown: (_) {
                  setState(() {
                    _parentScrollEnabled = false;
                  });
                },
                onPointerUp: (_) {
                  setState(() {
                    _parentScrollEnabled = true;
                  });
                },
                onPointerCancel: (_) {
                  setState(() {
                    _parentScrollEnabled = true;
                  });
                },
                child: SfPdfViewer.memory(
                  _pdfBytes!,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                ),
              ),
            ),
          ),
          // Floating Full Screen Button
          Positioned(
            top: 12,
            right: 12,
            child: ClipOval(
              child: Material(
                color: Colors.black.withValues(alpha: 0.4), // Kính mờ màu tối sang trọng
                child: InkWell(
                  onTap: () => _openFullScreenPdf(context, _pdfBytes!),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // fallback loading indicator when bytes are still loading or encountered an error
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: _pdfLoadError != null
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      _pdfLoadError!,
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đang tải tài liệu...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _openFullScreenPdf(BuildContext context, Uint8List bytes) {
    final title = _controller.document?['title']?.toString() ?? 'Tài liệu';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfFullScreenPage(
          pdfBytes: bytes,
          title: title,
        ),
      ),
    );
  }

  Widget _buildSpecsGrid(BuildContext context, String subjectCode, String fileType, String fileSize, int downloads) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        DocumentInfoTile(
          icon: Icons.code,
          label: 'MÃ MÔN HỌC',
          value: subjectCode.toUpperCase(),
          accentColor: Colors.indigo, // Indigo cho Mã môn học
        ),
        DocumentInfoTile(
          icon: Icons.file_download,
          label: 'LƯỢT TẢI',
          value: '$downloads',
          accentColor: const Color(0xFF059669), // Emerald Green lượt tải
        ),
      ],
    );
  }

  Widget _buildDescription(String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mô tả tài liệu',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          body.isNotEmpty ? body : 'Không có mô tả chi tiết cho tài liệu này.',
          style: const TextStyle(fontSize: 13, height: 1.45),
        ),
      ],
    );
  }

  Widget _buildTags(List tags, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thẻ liên quan',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((t) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
              ),
              child: Text(
                '#$t',
                style: TextStyle(
                  fontSize: 11,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsArea({
    required BuildContext context,
    required Color primaryColor,
    required ThemeData theme,
    required String? currentUserId,
    required Map<String, dynamic> doc,
    required bool hasMyReview,
    required Map<String, dynamic>? myReview,
    required List<dynamic> filteredReviews,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Redesigned Review & Rating Header Area
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đánh giá & Nhận xét',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _controller.avgRating != null
                          ? '${_controller.avgRating!.toStringAsFixed(1)} / 5.0'
                          : 'Chưa có đánh giá',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (_controller.reviewCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${_controller.reviewCount} lượt)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (!_showReviewForm && !hasMyReview)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showReviewForm = true;
                  });
                },
                icon: const Icon(Icons.rate_review, size: 14),
                label: const Text('Viết đánh giá'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  foregroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Đánh giá của bạn (Chỉ hiển thị khi đã đánh giá và không mở form sửa)
        if (hasMyReview && myReview != null && !_showReviewForm) ...[
          Card(
            elevation: 0,
            color: primaryColor.withValues(alpha: 0.03),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.2), width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        radius: 16,
                        child: Text(
                          (myReview['author'] as Map?)?['name']?.toString().isNotEmpty == true
                              ? (myReview['author'] as Map)['name'].toString()[0].toUpperCase()
                              : 'B',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Đánh giá của bạn',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.star, color: Colors.amber, size: 14),
                                  ],
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _startEditReview(
                                        (myReview['rating'] as num).toInt(),
                                        myReview['comment']?.toString() ?? '',
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Icon(Icons.edit, size: 15, color: primaryColor),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _deleteMyReview,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Icon(Icons.delete_outline, size: 15, color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    final rating = (myReview['rating'] as num?)?.toInt() ?? 5;
                                    return Icon(
                                      starIdx < rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 13,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  myReview['createdAt'] != null
                                      ? DateFormat('dd/MM/yyyy').format(
                                          myReview['createdAt'] is DateTime
                                              ? myReview['createdAt'] as DateTime
                                              : DateTime.tryParse(myReview['createdAt'].toString()) ?? DateTime.now(),
                                        )
                                      : '',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (myReview['comment']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      myReview['comment'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Collapsible Review Form Card
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Card(
            key: _reviewFormKey,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cảm nhận của bạn thế nào?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showReviewForm = false;
                          });
                        },
                        icon: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      final ratingVal = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _userRating = ratingVal;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            index < _userRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 28,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập nhận xét của bạn về tài liệu này...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showReviewForm = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Hủy', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _controller.submittingReview ? null : _submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: _controller.submittingReview
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Gửi đánh giá',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          crossFadeState: _showReviewForm ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        const SizedBox(height: 20),

        // Community Reviews List with Unified Filter & Sorting Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nhận xét cộng đồng',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                // Bộ lọc sao Popup Menu
                PopupMenuButton<String>(
                  initialValue: _selectedRatingFilter,
                  onSelected: (String filter) {
                    setState(() {
                      _selectedRatingFilter = filter;
                      _visibleReviewsCount = 3;
                    });
                  },
                  itemBuilder: (context) => ['Tất cả', '5 ★', '4 ★', '3 ★', '2 ★', '1 ★'].map((f) {
                    return PopupMenuItem<String>(
                      value: f,
                      child: Row(
                        children: [
                          Icon(Icons.star, color: f == 'Tất cả' ? Colors.grey : Colors.amber, size: 15),
                          const SizedBox(width: 8),
                          Text(f, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _selectedRatingFilter == 'Tất cả' 
                          ? theme.cardColor
                          : primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedRatingFilter == 'Tất cả'
                            ? theme.dividerColor
                            : primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star, 
                          size: 13, 
                          color: _selectedRatingFilter == 'Tất cả' ? Colors.grey : Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedRatingFilter,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _selectedRatingFilter == 'Tất cả'
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                                : primaryColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down, 
                          size: 13, 
                          color: _selectedRatingFilter == 'Tất cả' ? Colors.grey : primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Sắp xếp nhận xét Popup Menu
                PopupMenuButton<String>(
                  initialValue: _selectedSortOrder,
                  onSelected: (String order) {
                    setState(() {
                      _selectedSortOrder = order;
                      _visibleReviewsCount = 3;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Mới nhất',
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 16),
                          SizedBox(width: 8),
                          Text('Mới nhất', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Cũ nhất',
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 16),
                          SizedBox(width: 8),
                          Text('Cũ nhất', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Đánh giá cao nhất',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Đánh giá cao nhất', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Đánh giá thấp nhất',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Đánh giá thấp nhất', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_vert, size: 13, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          _selectedSortOrder,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down, size: 13, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (filteredReviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(Icons.rate_review_outlined, color: Colors.grey, size: 36),
                const SizedBox(height: 10),
                Text(
                  _selectedRatingFilter == 'Tất cả'
                      ? 'Chưa có nhận xét nào.\nHãy viết nhận xét đầu tiên cho tài liệu này!'
                      : 'Không có nhận xét $_selectedRatingFilter nào.',
                  style: const TextStyle(color: Colors.grey, height: 1.4, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredReviews.length > _visibleReviewsCount
                ? _visibleReviewsCount
                : filteredReviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final rev = filteredReviews[index] as Map<String, dynamic>;
              final isAuthor = rev['userId'] == doc['authorId'];
              return DocumentReviewCard(
                review: rev,
                isAuthor: isAuthor,
                primaryColor: primaryColor,
              );
            },
          ),
          
          // Load more reviews button (Pagination UI)
          if (filteredReviews.length > _visibleReviewsCount) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Đang hiển thị $_visibleReviewsCount trên ${filteredReviews.length} nhận xét',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _visibleReviewsCount += 5;
                });
              },
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              label: const Text('Xem thêm nhận xét'),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size.fromHeight(48),
                backgroundColor: primaryColor.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

