import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';

class PlaceDetailPage extends StatefulWidget {
  const PlaceDetailPage({super.key, required this.placeId});

  final String placeId;

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  Map<String, dynamic>? _place;
  List<dynamic> _documents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final place = await ApiClient.instance.get('/document/${widget.placeId}');
      final ownerId = place['author']?['id']?.toString() ?? place['authorId']?.toString();
      if (ownerId == null || ownerId.isEmpty) {
        throw Exception('Không xác định được chủ địa điểm');
      }
      final docsRes = await SfinityApp.documentRepository.getDocuments(
        type: 'document',
        authorId: ownerId,
        publishedOnly: true,
        limit: 50,
      );

      _place = place;
      _documents = docsRes['items'] as List? ?? [];
    } on DioException catch (e) {
      _error = ApiClient.instance.errorMessage(e);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openUploadDocument(String placeTitle) {
    context.push(
      RouteNames.documentCreate,
      extra: {
        'contentType': 'document',
        'placeId': widget.placeId,
        'placeTitle': placeTitle,
      },
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết địa điểm')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _place == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết địa điểm')),
        body: ErrorView(
          message: _error ?? 'Không tải được địa điểm',
          onRetry: _load,
        ),
      );
    }

    final place = _place!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = place['title']?.toString() ?? 'Địa điểm';
    final body = place['body']?.toString() ?? '';
    final author = place['author'] as Map<String, dynamic>?;
    final ownerName = author?['name']?.toString() ?? 'Người dùng';
    final currentUserId = SfinityApp.auth.user?['id']?.toString();
    final ownerId = author?['id']?.toString() ?? place['authorId']?.toString();
    final isMine = currentUserId != null && ownerId != null && currentUserId == ownerId;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết địa điểm')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: isDark ? 0.35 : 0.12),
                    theme.colorScheme.secondary.withValues(alpha: isDark ? 0.2 : 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : primary.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.place_rounded, color: primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Chủ địa điểm',
                    value: ownerName,
                    isDark: isDark,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Mô tả',
                      value: body,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            if (isMine) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, theme.colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: FilledButton.icon(
                  onPressed: () => _openUploadDocument(title),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                  label: const Text(
                    'Tải tài liệu cho địa điểm này',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chỉ bạn — chủ địa điểm — mới có thể đăng tài liệu tại đây.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Tài liệu tại địa điểm',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (_documents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE8EAED),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 36,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMine
                          ? 'Chưa có tài liệu. Bấm nút phía trên để tải lên.'
                          : 'Chưa có tài liệu công khai ở địa điểm này.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._documents.map((raw) {
                final item = raw as Map<String, dynamic>;
                final docId = item['id']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: docId.isEmpty ? null : () => context.push('/document/$docId'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE8EAED),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.description_outlined, color: primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']?.toString() ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Nhấn để xem và tải',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
