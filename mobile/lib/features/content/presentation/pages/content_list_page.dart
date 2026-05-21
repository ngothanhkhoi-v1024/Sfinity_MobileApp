import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';

class ContentListPage extends StatefulWidget {
  const ContentListPage({super.key, this.embedded = false});

  /// Khi true: không bọc Scaffold (dùng trong shell tab Tài liệu).
  final bool embedded;

  @override
  State<ContentListPage> createState() => _ContentListPageState();
}

class _ContentListPageState extends State<ContentListPage> {
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
      final res = await ApiClient.instance.get('/content', query: {
        'publishedOnly': 'true',
        'limit': '50',
      });
      final raw = res['items'] as List? ?? [];
      _items = raw.where((e) {
        final body = (e as Map<String, dynamic>)['body']?.toString() ?? '';
        return !body.contains('type:place');
      }).toList();
    } on DioException catch (e) {
      _error = ApiClient.instance.errorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Chưa có tài liệu học tập')),
              ],
            )
          : ListView.builder(
              padding: widget.embedded ? const EdgeInsets.fromLTRB(12, 8, 12, 100) : null,
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i] as Map<String, dynamic>;
                final body = item['body']?.toString() ?? '';
                if (body.contains('type:place')) return const SizedBox.shrink();
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(item['title']?.toString() ?? ''),
                    subtitle: Text(
                      body.split('\n').first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/content/${item['id']}'),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tài liệu',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context.push(
                    RouteNames.contentCreate,
                    extra: const {'contentType': 'document'},
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài liệu học tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(
              RouteNames.contentCreate,
              extra: const {'contentType': 'document'},
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
