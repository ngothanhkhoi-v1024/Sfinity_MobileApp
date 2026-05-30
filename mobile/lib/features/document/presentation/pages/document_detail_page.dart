import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:intl/intl.dart';

import '../../../../app.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/document_detail_controller.dart';
import '../widgets/document_info_tile.dart';

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
        final hasMyReview = _controller.reviews.any((e) => (e as Map)['userId'] == currentUserId);

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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        fileType == 'LINK' ? Icons.open_in_new : Icons.file_download_outlined,
                      ),
                onPressed: _controller.downloading ? null : _downloadFile,
                tooltip: 'Tải xuống',
              ),
              // Share Button
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: _share,
                tooltip: 'Chia sẻ',
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
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            physics: _parentScrollEnabled
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium COMPACT Inline Header
                Row(
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
                        fileType == 'PDF' ? Icons.picture_as_pdf : Icons.article,
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
                ),
                const SizedBox(height: 16),

                // Direct PDF View Container with Gestures Fix
                if (fileUrl.isNotEmpty) ...[
                  Container(
                    height: 460,
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
                        child: SfPdfViewer.network(
                          fileUrl,
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Grid Specs Info
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    DocumentInfoTile(
                      icon: Icons.code,
                      label: 'MÃ MÔN HỌC',
                      value: subjectCode.toUpperCase(),
                    ),
                    DocumentInfoTile(
                      icon: Icons.insert_drive_file,
                      label: 'ĐỊNH DẠNG',
                      value: fileType,
                    ),
                    DocumentInfoTile(
                      icon: Icons.data_usage,
                      label: 'DUNG LƯỢNG',
                      value: fileSize,
                    ),
                    DocumentInfoTile(
                      icon: Icons.file_download,
                      label: 'LƯỢT TẢI',
                      value: '$downloads',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Document Description
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

                // Tags List
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
                          color: primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          '#$t',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],

                const Divider(),
                const SizedBox(height: 24),

                // Redesigned Review & Rating Header Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đánh giá & Nhận xét',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                        icon: const Icon(Icons.rate_review, size: 16),
                        label: const Text('Viết đánh giá'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          foregroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Collapsible Review Form Card
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Card(
                    key: _reviewFormKey,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cảm nhận của bạn thế nào?',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _showReviewForm = false;
                                  });
                                },
                                icon: const Icon(Icons.close, size: 18),
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
                                    size: 32,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Nhập nhận xét của bạn về tài liệu này...',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 14),
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
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Hủy'),
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
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: _controller.submittingReview
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Gửi đánh giá',
                                          style: TextStyle(fontWeight: FontWeight.bold),
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

                // Community Reviews List with Edit/Delete features
                const Text(
                  'Nhận xét từ sinh viên khác',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_controller.reviews.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.rate_review_outlined, color: Colors.grey, size: 40),
                        const SizedBox(height: 10),
                        Text(
                          'Chưa có nhận xét nào.\nHãy viết nhận xét đầu tiên cho tài liệu này!',
                          style: TextStyle(color: Colors.grey, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _controller.reviews.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rev = _controller.reviews[index] as Map<String, dynamic>;
                      final authorName = (rev['author'] as Map?)?['name']?.toString() ?? 'Người dùng Sfinity';
                      final rating = (rev['rating'] as num?)?.toInt() ?? 5;
                      final comment = rev['comment']?.toString() ?? '';
                      final dateVal = rev['createdAt'] != null
                          ? (rev['createdAt'] is DateTime
                              ? rev['createdAt'] as DateTime
                              : DateTime.tryParse(rev['createdAt'].toString()) ?? DateTime.now())
                          : DateTime.now();
                      final dateStr = DateFormat('dd/MM/yyyy').format(dateVal);
                      final isMyReview = rev['userId'] == currentUserId;

                      return Card(
                        elevation: 0,
                        color: theme.cardColor,
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
                                children: [
                                  CircleAvatar(
                                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                                    radius: 18,
                                    child: Text(
                                      authorName.isNotEmpty ? authorName[0].toUpperCase() : 'S',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
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
                                            Row(
                                              children: [
                                                Text(
                                                  authorName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                                if (rev['userId'] == doc['authorId']) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                                    ),
                                                    child: const Text(
                                                      'Tác giả',
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (isMyReview) ...[
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => _startEditReview(rating, comment),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      child: Icon(Icons.edit, size: 16, color: primaryColor),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: _deleteMyReview,
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Row(
                                              children: List.generate(5, (starIdx) {
                                                return Icon(
                                                  starIdx < rating ? Icons.star : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 14,
                                                );
                                              }),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              dateStr,
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (comment.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  comment,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
