import 'assistant_action.dart';

enum AssistantMessageRole { user, assistant }

class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.content,
    this.isError = false,
    this.actions = const [],
    this.sources = const [],
  });

  final AssistantMessageRole role;
  final String content;
  final bool isError;
  final List<AssistantAction> actions;
  final List<String> sources;

  Map<String, String> toHistoryItem() => {
        'role': role == AssistantMessageRole.user ? 'user' : 'assistant',
        'content': content,
      };
}
