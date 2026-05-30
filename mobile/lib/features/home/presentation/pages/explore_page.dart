import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../study_near_me/presentation/controllers/study_near_me_controller.dart';
import '../../../study_near_me/presentation/widgets/study_near_me_button.dart';
import '../../../study_near_me/presentation/widgets/study_near_me_results_sheet.dart';

/// Tab Khám phá — feed địa điểm & tài liệu.
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  late final StudyNearMeController _studyNearMeCtrl;

  @override
  void initState() {
    super.initState();
    _studyNearMeCtrl = StudyNearMeController();
    _studyNearMeCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _studyNearMeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onStudyNearMe() async {
    final ok = await _studyNearMeCtrl.loadNearby();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_studyNearMeCtrl.error ?? 'Không tìm được kết quả')),
      );
      return;
    }
    final result = _studyNearMeCtrl.result;
    if (result != null) {
      await StudyNearMeResultsSheet.show(
        context,
        result: result,
        onRetry: _onStudyNearMe,
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('/document', query: {
        'publishedOnly': 'true',
        'limit': '20',
      });
      _items = res['items'] as List? ?? [];
    } on DioException catch (e) {
      _error = ApiClient.instance.errorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isPlace(Map<String, dynamic> item) {
    if (item['type']?.toString() == 'place') return true;
    final body = item['body']?.toString() ?? '';
    return body.contains('type:place');
  }

  void _openItem(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    if (_isPlace(item)) {
      context.push('/places/$id');
    } else {
      context.push('/document/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
          Text(
            'Khám phá',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFF2F2F2)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Địa điểm học tập và tài liệu từ cộng đồng',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: StudyNearMeButton(
              loading: _studyNearMeCtrl.loading,
              onPressed: _onStudyNearMe,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.search,
                  label: 'Tìm kiếm',
                  onTap: () => context.push(RouteNames.search),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.bookmark_outline,
                  label: 'Đã lưu',
                  onTap: () => context.push(RouteNames.favorites),
                ),
              ),
            ],
          ),
           const SizedBox(height: 24),
           Text(
             'Mới nhất',
             style: Theme.of(context).textTheme.titleMedium?.copyWith(
               color: Theme.of(context).brightness == Brightness.dark
                   ? const Color(0xFFF2F2F2)
                   : null,
             ),
           ),
          const SizedBox(height: 8),
           if (_items.isEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 32),
               child: Center(
                 child: Text(
                   'Chưa có bài chia sẻ — hãy là người đầu tiên!',
                   style: TextStyle(
                     color: Theme.of(context).brightness == Brightness.dark
                         ? Colors.grey.shade400
                         : null,
                   ),
                 ),
               ),
             )
          else
            ..._items.map((raw) {
               final item = raw as Map<String, dynamic>;
               final isPlace = _isPlace(item);
               final isDark = Theme.of(context).brightness == Brightness.dark;
               return Card(
                 margin: const EdgeInsets.only(bottom: 10),
                 child: ListTile(
                   leading: CircleAvatar(
                     backgroundColor: isDark
                         ? (isPlace ? Colors.red.shade900 : Colors.blue.shade900)
                         : (isPlace ? Colors.red.shade50 : Colors.blue.shade50),
                     child: Icon(
                       isPlace ? Icons.place_outlined : Icons.menu_book_outlined,
                       color: isPlace ? Colors.red.shade400 : Colors.blue.shade400,
                     ),
                   ),
                   title: Text(
                     item['title']?.toString() ?? '',
                     style: TextStyle(
                       color: isDark ? const Color(0xFFF2F2F2) : null,
                     ),
                   ),
                  subtitle: Text(
                    isPlace ? 'Địa điểm' : 'Tài liệu học tập',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                   trailing: Icon(
                     Icons.chevron_right,
                     color: isDark ? Colors.grey.shade500 : null,
                   ),
                  onTap: () => _openItem(item),
                ),
              );
            }),
        ],
      ),
        ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(
                icon,
                color: isDark ? const Color(0xFFF2F2F2) : null,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFF2F2F2) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
