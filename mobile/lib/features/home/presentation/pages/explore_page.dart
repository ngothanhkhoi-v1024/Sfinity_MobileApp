import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';

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
    final body = item['body']?.toString() ?? '';
    return body.contains('type:place');
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text(
            'Khám phá',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Địa điểm học tập và tài liệu từ cộng đồng',
            style: TextStyle(color: Colors.grey.shade600),
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
          Text('Mới nhất', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Chưa có bài chia sẻ — hãy là người đầu tiên!')),
            )
          else
            ..._items.map((raw) {
              final item = raw as Map<String, dynamic>;
              final isPlace = _isPlace(item);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPlace ? Colors.red.shade50 : Colors.blue.shade50,
                    child: Icon(
                      isPlace ? Icons.place_outlined : Icons.menu_book_outlined,
                      color: isPlace ? Colors.red.shade700 : Colors.blue.shade700,
                    ),
                  ),
                  title: Text(item['title']?.toString() ?? ''),
                  subtitle: Text(
                    isPlace ? 'Địa điểm' : 'Tài liệu học tập',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/document/${item['id']}'),
                ),
              );
            }),
        ],
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
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
