import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/i18n/app_text.dart';
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
    final l10n = context.l10n;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    if (_items.isEmpty) {
      return Center(child: Text(l10n.noFavoritesYet));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final fav = _items[i] as Map<String, dynamic>;
          final document = fav['document'] as Map<String, dynamic>?;
          final docId = document?['id']?.toString() ?? '';
          final isPlace = document?['type']?.toString() == 'place';
          return ListTile(
            leading: Icon(isPlace ? Icons.place_outlined : Icons.description_outlined),
            title: Text(document?['title']?.toString() ?? ''),
            subtitle: isPlace ? const Text('Địa điểm học tập') : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: docId.isEmpty
                ? null
                : () => context.push(isPlace ? '/places/$docId' : '/document/$docId'),
          );
        },
      ),
    );
  }
}
