import 'dart:collection';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:intl/intl.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/document_detail_controller.dart';
import '../widgets/document_info_tile.dart';
import '../widgets/document_review_card.dart';
import '../../../../core/constants/route_names.dart';
import 'pdf_full_screen_page.dart';

class DocumentDetailPage extends StatefulWidget {
  const DocumentDetailPage({super.key, required this.documentId});

  final String documentId;

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  static final LinkedHashMap<String, Uint8List> _pdfCache = LinkedHashMap<String, Uint8List>();
  static const int _maxPdfCacheEntries = 6;

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
  String _selectedRatingFilter = 'ALL';
  String _selectedSortOrder = 'newest';
  int _visibleReviewsCount = 5;
  
  Uint8List? _pdfBytes;
  bool _pdfBytesLoading = false;
  String? _pdfLoadError;
  String? _cachedPdfUrl;

  Uint8List? _getCachedPdf(String url) {
    final cached = _pdfCache.remove(url);
    if (cached == null) {
      return null;
    }
    _pdfCache[url] = cached;
    return cached;
  }

  void _storeCachedPdf(String url, Uint8List bytes) {
    _pdfCache.remove(url);
    _pdfCache[url] = bytes;
    while (_pdfCache.length > _maxPdfCacheEntries) {
      _pdfCache.remove(_pdfCache.keys.first);
    }
  }

  Future<void> _loadPdfBytes(String url) async {
    if (_cachedPdfUrl == url && (_pdfBytes != null || _pdfBytesLoading)) return;

    final cached = _getCachedPdf(url);
    if (cached != null) {
      setState(() {
        _cachedPdfUrl = url;
        _pdfBytes = cached;
        _pdfBytesLoading = false;
        _pdfLoadError = null;
      });
      return;
    }

    setState(() {
      _cachedPdfUrl = url;
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
        final bytes = Uint8List.fromList(response.data!);
        _storeCachedPdf(url, bytes);
        setState(() {
          _pdfBytes = bytes;
          _pdfBytesLoading = false;
        });
      } else {
        setState(() {
          _pdfLoadError = context.l10n.cannotOpenPDF('');
          _pdfBytesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _pdfLoadError = context.l10n.cannotConnectServer(e.toString());
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
      final l10n = context.l10n;
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? l10n.favoriteDocument : l10n.unfavoriteDocument),
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
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Circular icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade100, width: 2),
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red.shade600,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Xóa tài liệu?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              // Description
              Text(
                'Tài liệu này sẽ bị xóa vĩnh viễn và\nkhông thể khôi phục lại.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Warning chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Hành động này không thể hoàn tác',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Hủy bỏ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Xóa tài liệu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        setState(() {
          _pdfBytes = null;
        });
        await SfinityApp.documentRepository.deleteDocument(docId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Đã xóa tài liệu thành công'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(12),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Xóa thất bại: $e')),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
      }
    }
  }

  Future<void> _downloadFile() async {
    if (_controller.document == null) return;
    final fileUrl = _controller.document!['fileUrl']?.toString() ?? '';
    final l10n = context.l10n;
    if (fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDownloadLink)),
      );
      return;
    }

    final success = await _controller.triggerDownload(fileUrl);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.openDocumentSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else if (_controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotOpenDocument(_controller.error!))),
      );
    }
  }

  Future<void> _submitReview() async {
    if (_userRating < 1 || _userRating > 5) return;
    final l10n = context.l10n;

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
          content: Text(l10n.rateDocumentSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else if (_controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.rateDocumentFailed('')} ${_controller.error}')),
      );
    }
  }

  Future<void> _deleteMyReview() async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.ratingDeleted),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelBtn2),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      final l10n2 = context.l10n;
      final success = await _controller.deleteReview(widget.documentId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n2.ratingDeleted),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else if (_controller.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n2.cannotDeleteRating(_controller.error!))),
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
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.document == null && _controller.error == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.studyMaterials)),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          );
        }

        if (_controller.error != null && _controller.document == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.studyMaterials)),
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
        final subjectCode = doc['subjectCode']?.toString() ?? l10n.studyDocument;

        final catName = (doc['category'] as Map?)?['name']?.toString();
        final category = catName != null ? l10n.translateCategory(catName) : l10n.documents;
        final fileUrl = doc['fileUrl']?.toString() ?? '';
        final isAuthor = doc['authorId']?.toString() == currentUserId;

        if (_cachedPdfUrl != fileUrl) {
          _cachedPdfUrl = fileUrl;
          _pdfBytes = fileUrl.isEmpty ? null : _getCachedPdf(fileUrl);
          _pdfBytesLoading = false;
          _pdfLoadError = null;
        }

        if (fileUrl.isNotEmpty && _pdfBytes == null && !_pdfBytesLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadPdfBytes(fileUrl);
            }
          });
        }
        
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

        final publicReviews = [
          if (authorReview != null) authorReview,
          ...remainingReviews,
        ];

        final filteredReviews = publicReviews.where((rev) {
          if (_selectedRatingFilter == 'ALL') return true;
          final rating = (rev['rating'] as num?)?.toInt() ?? 5;
          return '$rating ★' == _selectedRatingFilter;
        }).toList();

        filteredReviews.sort((a, b) {
          final isAuthorA = a['userId'] == doc['authorId'];
          final isAuthorB = b['userId'] == doc['authorId'];
          if (isAuthorA && !isAuthorB) return -1;
          if (!isAuthorA && isAuthorB) return 1;

          if (_selectedSortOrder == 'newest') {
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
            return dateB.compareTo(dateA);
          } else if (_selectedSortOrder == 'oldest') {
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
            return dateA.compareTo(dateB);
          } else if (_selectedSortOrder == 'highest_rating') {
            final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
            final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
            return ratingB.compareTo(ratingA);
          } else if (_selectedSortOrder == 'lowest_rating') {
            final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
            final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
            return ratingA.compareTo(ratingB);
          }
          return 0;
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.studyMaterials, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
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
                tooltip: l10n.download,
              ),
              // Save/Bookmark Button
              if (!_loadingFavorite)
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: _isFavorite ? primaryColor : null,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: _isFavorite ? l10n.unfavoriteDocument : l10n.favoriteDocument,
                ),
              // 3-dots overflow popup menu
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
                    case 'report':
                      if (context.mounted) {
                        context.push(
                          RouteNames.report,
                          extra: {
                            'targetType': 'document',
                            'targetId': doc['id'].toString(),
                          },
                        );
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (isAuthor) ...[
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ] else ...[
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(Icons.report_problem_outlined, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(l10n.reportViolation, style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          body: isLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (fileUrl.isNotEmpty)
                      Expanded(
                        flex: 11,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                          child: _buildPdfViewer(context, fileUrl, theme),
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context, String title, String category, Color primaryColor) {
    final l10n = context.l10n;
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
                      l10n.noRating,
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
    final l10n = context.l10n;
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
          Positioned(
            top: 12,
            right: 12,
            child: ClipOval(
              child: Material(
                color: Colors.black.withValues(alpha: 0.4),
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
                    l10n.loading,
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
    final l10n = this.context.l10n;
    final title = _controller.document?['title']?.toString() ?? l10n.documents;
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
    final l10n = context.l10n;
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
          label: l10n.subjectCode.toUpperCase(),
          value: subjectCode.toUpperCase(),
          accentColor: Colors.indigo,
        ),
        DocumentInfoTile(
          icon: Icons.file_download,
          label: l10n.downloads.toUpperCase(),
          value: '$downloads',
          accentColor: const Color(0xFF059669),
        ),
      ],
    );
  }

  Widget _buildDescription(String body) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.description,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          body.isNotEmpty ? body : l10n.noResourceFound,
          style: const TextStyle(fontSize: 13, height: 1.45),
        ),
      ],
    );
  }

  Widget _buildTags(List tags, Color primaryColor) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.relatedTags,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ratingAndComments,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _controller.avgRating != null
                          ? '${_controller.avgRating!.toStringAsFixed(1)} / 5.0'
                          : l10n.noRating,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (_controller.reviewCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${_controller.reviewCount})',
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
                label: Text(l10n.sendRating),
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
                                Row(
                                  children: [
                                    Text(
                                      l10n.yourRating,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
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
                      Text(
                        l10n.ratingHint,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                    decoration: InputDecoration(
                      hintText: l10n.ratingHint,
                      border: const OutlineInputBorder(),
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
                          child: Text(l10n.cancelBtn2, style: const TextStyle(fontSize: 13)),
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
                              : Text(
                                  l10n.sendRating,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.noComments,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                PopupMenuButton<String>(
                  initialValue: _selectedRatingFilter,
                  onSelected: (String filter) {
                    setState(() {
                      _selectedRatingFilter = filter;
                      _visibleReviewsCount = 3;
                    });
                  },
                  itemBuilder: (context) => ['ALL', '5 ★', '4 ★', '3 ★', '2 ★', '1 ★'].map((f) {
                    return PopupMenuItem<String>(
                      value: f,
                      child: Row(
                        children: [
                          Icon(Icons.star, color: f == 'ALL' ? Colors.grey : Colors.amber, size: 15),
                          const SizedBox(width: 8),
                          Text(f == 'ALL' ? l10n.all : f, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _selectedRatingFilter == 'ALL' 
                          ? theme.cardColor
                          : primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedRatingFilter == 'ALL'
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
                          color: _selectedRatingFilter == 'ALL' ? Colors.grey : Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedRatingFilter == 'ALL' ? l10n.all : _selectedRatingFilter,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _selectedRatingFilter == 'ALL'
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                                : primaryColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down, 
                          size: 13, 
                          color: _selectedRatingFilter == 'ALL' ? Colors.grey : primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                PopupMenuButton<String>(
                  initialValue: _selectedSortOrder,
                  onSelected: (String order) {
                    setState(() {
                      _selectedSortOrder = order;
                      _visibleReviewsCount = 3;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'newest',
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 8),
                          Text(l10n.newest, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'oldest',
                      child: Row(
                        children: [
                          const Icon(Icons.history, size: 16),
                          const SizedBox(width: 8),
                          Text(l10n.oldest, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'highest_rating',
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(l10n.highestRating, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'lowest_rating',
                      child: Row(
                        children: [
                          const Icon(Icons.star_border, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(l10n.lowestRating, style: const TextStyle(fontSize: 12)),
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
                          _selectedSortOrder == 'newest'
                              ? l10n.newest
                              : _selectedSortOrder == 'oldest'
                                  ? l10n.oldest
                                  : _selectedSortOrder == 'highest_rating'
                                      ? l10n.highestRating
                                      : l10n.lowestRating,
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
                  _selectedRatingFilter == 'ALL'
                      ? l10n.noCommentsFound
                      : l10n.noComments,
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
          
          if (filteredReviews.length > _visibleReviewsCount) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.noCommentsFound,
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
              label: Text(l10n.loadMoreComments),
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
