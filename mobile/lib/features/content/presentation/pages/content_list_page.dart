import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';

class ContentListPage extends StatefulWidget {
  const ContentListPage({super.key});

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
      _items = res['items'] as List? ?? [];
    } on DioException catch (e) {
      _error = ApiClient.instance.errorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nội dung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RouteNames.contentCreate),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Chưa có nội dung'))])
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final item = _items[i] as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(item['title']?.toString() ?? ''),
                                subtitle: Text(
                                  item['body']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push('/content/${item['id']}'),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
