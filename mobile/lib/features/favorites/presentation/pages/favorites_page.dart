import 'package:flutter/material.dart';

import '../../../../shared/widgets/placeholder_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Yêu thích / Bookmark',
      embedded: true,
    );
  }
}
