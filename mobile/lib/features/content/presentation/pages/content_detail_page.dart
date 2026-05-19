import 'package:flutter/material.dart';

import '../../../../shared/widgets/placeholder_page.dart';

class ContentDetailPage extends StatelessWidget {
  const ContentDetailPage({super.key, this.contentId});

  final String? contentId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(title: 'Chi tiết', subtitle: contentId);
  }
}
