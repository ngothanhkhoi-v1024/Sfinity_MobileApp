import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Trang xem tài liệu PDF toàn màn hình tải tức thì từ bộ nhớ đệm bytes
class PdfFullScreenPage extends StatelessWidget {
  const PdfFullScreenPage({
    super.key,
    required this.pdfBytes,
    required this.title,
  });

  final Uint8List pdfBytes;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SfPdfViewer.memory(
          pdfBytes,
          canShowScrollHead: true,
          canShowScrollStatus: true,
        ),
      ),
    );
  }
}
