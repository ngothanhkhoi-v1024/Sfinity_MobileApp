import 'package:flutter/material.dart';

import '../../../../shared/widgets/placeholder_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Trang chủ',
      subtitle: 'Danh sách nội dung — ListView / infinite scroll',
      embedded: true,
    );
  }
}
