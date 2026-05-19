import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/error_view.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
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
      _items = await ApiClient.instance.getList('/favorites');
    } on DioException catch (e) {
      _error = ApiClient.instance.errorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    if (_items.isEmpty) {
      return const Center(child: Text('Chưa có mục yêu thích'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final fav = _items[i] as Map<String, dynamic>;
          final content = fav['content'] as Map<String, dynamic>?;
          return ListTile(
            title: Text(content?['title']?.toString() ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/content/${content?['id']}'),
          );
        },
      ),
    );
  }
}
