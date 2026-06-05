import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/assistant_message.dart';
import '../../data/services/assistant_api_service.dart';

class AssistantController extends ChangeNotifier {
  AssistantController(this._api);

  final AssistantApiService _api;

  final List<AssistantMessage> _messages = [];
  bool _loading = false;
  String? _context;

  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get loading => _loading;
  String? get context => _context;

  void setContext(String? context) {
    if (_context == context) return;
    _context = context;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;

    _messages.add(AssistantMessage(role: AssistantMessageRole.user, content: trimmed));
    _loading = true;
    notifyListeners();

    try {
      final history = _messages
          .where((m) => !m.isError)
          .map((m) => m.toHistoryItem())
          .toList();
      if (history.isNotEmpty) history.removeLast();

      final data = await _api.sendMessage(
        message: trimmed,
        context: _context,
        history: history.length > 10 ? history.sublist(history.length - 10) : history,
      );

      final reply = data['reply']?.toString() ?? '';
      _messages.add(
        AssistantMessage(
          role: AssistantMessageRole.assistant,
          content: reply.isNotEmpty ? reply : '…',
        ),
      );
    } on DioException catch (e) {
      _messages.add(
        AssistantMessage(
          role: AssistantMessageRole.assistant,
          content: ApiClient.instance.errorMessage(e),
          isError: true,
        ),
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
