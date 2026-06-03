import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CropResult {
  final File file;
  final CropData transform;

  CropResult({required this.file, required this.transform});
}

class CropData {
  final double scale;
  final double tx;
  final double ty;
  final Size? sourceSize;

  CropData({
    required this.scale,
    required this.tx,
    required this.ty,
    this.sourceSize,
  });
}

class AvatarCropPage extends StatefulWidget {
  const AvatarCropPage({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _controller = TransformationController();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerImage();
    });
  }

  void _centerImage() {
    final cropRenderBox = _cropKey.currentContext?.findRenderObject() as RenderBox?;
    if (cropRenderBox == null) return;

    final cropSize = cropRenderBox.size.shortestSide;

    _controller.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_processing) return;
    Navigator.of(context).pop(null);
  }

  CropData _extractTransform() {
    final m = _controller.value;
    final a = m.entry(0, 0), b = m.entry(1, 0);
    final scale = math.sqrt(a * a + b * b);
    final tx = m.entry(0, 3);
    final ty = m.entry(1, 3);
    return CropData(
      scale: scale,
      tx: tx,
      ty: ty,
      sourceSize: _getCropSize(),
    );
  }

  Size? _getCropSize() {
    final renderBox = _cropKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size;
  }

  Future<void> _confirm() async {
    if (_processing) return;

    final cropSize = _getCropSize();
    if (cropSize == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: không xác định được kích thước ảnh')),
        );
      }
      return;
    }

    setState(() => _processing = true);

    try {
      final pixelRatio = View.of(context).devicePixelRatio;
      final boundary = _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: không chụp được ảnh')),
          );
        }
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final img = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();

      if (byteData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: không mã hóa được ảnh')),
          );
        }
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await Directory.systemTemp.createTemp('sfinity_avatar_');
      final outFile = File('${tempDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png');
      await outFile.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      Navigator.of(context).pop(CropResult(
        file: outFile,
        transform: CropData(scale: 1.0, tx: 0, ty: 0, sourceSize: null),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cắt ảnh thất bại: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _processing ? null : _cancel,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      'Cắt ảnh đại diện',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Kéo hoặc phóng to ảnh để chọn vùng hiển thị avatar.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RepaintBoundary(
                          key: _cropKey,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: ColoredBox(
                              color: const Color(0xFF111111),
                              child: InteractiveViewer(
                                transformationController: _controller,
                                minScale: 0.5,
                                maxScale: 4.0,
                                panEnabled: true,
                                boundaryMargin: const EdgeInsets.all(100),
                                clipBehavior: Clip.hardEdge,
                                child: Image.file(
                                  widget.imageFile,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white70, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _processing ? null : _cancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _processing ? null : _confirm,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _processing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Đồng ý'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
