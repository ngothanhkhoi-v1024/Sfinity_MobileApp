import 'package:flutter/material.dart';

import '../../../../shared/widgets/placeholder_page.dart';

class ContentFormPage extends StatelessWidget {
  const ContentFormPage({super.key, this.isEdit = false});

  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(title: isEdit ? 'Sửa nội dung' : 'Tạo nội dung');
  }
}
