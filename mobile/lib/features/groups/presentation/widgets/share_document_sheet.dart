import 'package:flutter/material.dart';
import '../../../../app.dart';

class ShareDocumentSheet extends StatefulWidget {
  const ShareDocumentSheet({super.key, required this.onShare});
  final Future<void> Function(String id, String title) onShare;

  @override
  State<ShareDocumentSheet> createState() => _ShareDocumentSheetState();
}

class _ShareDocumentSheetState extends State<ShareDocumentSheet> {
  List<dynamic> _docs = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  bool _manualMode = false;

  final _idCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _titleCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDocs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SfinityApp.documentRepository.getDocuments(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: 30,
      );
      final items = res['items'] as List? ?? [];
      setState(() {
        _docs = items.where((e) {
          final itemMap = e as Map<String, dynamic>;
          final type = itemMap['type']?.toString();
          if (type != null) {
            return type == 'document';
          }
          final body = itemMap['body']?.toString() ?? '';
          return !body.contains('type:place');
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách tài liệu. Vui lòng thử lại.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chia sẻ tài liệu',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _manualMode = !_manualMode;
                  });
                },
                icon: Icon(_manualMode ? Icons.list_alt_rounded : Icons.edit_note_rounded),
                label: Text(_manualMode ? 'Chọn từ danh sách' : 'Nhập ID thủ công'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_manualMode) ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    TextField(
                      controller: _idCtrl,
                      decoration: InputDecoration(
                        labelText: 'ID tài liệu',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tên tài liệu',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.picture_as_pdf_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final id = _idCtrl.text.trim();
                          final title = _titleCtrl.text.trim();
                          if (id.isEmpty || title.isEmpty) return;
                          await widget.onShare(id, title);
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Chia sẻ vào nhóm'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tài liệu học tập...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadDocs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onSubmitted: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
                _loadDocs();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, style: TextStyle(color: cs.error)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadDocs,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : _docs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_open_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Không tìm thấy tài liệu nào',
                                    style: TextStyle(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _docs.length,
                              itemBuilder: (ctx, i) {
                                final doc = _docs[i] as Map<String, dynamic>;
                                final docId = doc['id']?.toString() ?? '';
                                final docTitle = doc['title']?.toString() ?? 'Tài liệu không tên';
                                final subjectCode = doc['subjectCode']?.toString();
                                final category = (doc['category'] as Map?)?['name']?.toString() ?? 'Tài liệu';

                                return Card(
                                  elevation: 0,
                                  color: cs.surfaceContainerLowest,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.description_rounded,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    ),
                                    title: Text(
                                      docTitle,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${subjectCode != null ? "$subjectCode • " : ""}$category',
                                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                    trailing: TextButton.icon(
                                      onPressed: () async {
                                        await widget.onShare(docId, docTitle);
                                      },
                                      icon: const Icon(Icons.send_rounded, size: 14),
                                      label: const Text('Chia sẻ'),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ],
      ),
    );
  }
}
