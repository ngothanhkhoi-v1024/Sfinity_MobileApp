enum AssistantMessageRole { user, assistant }

class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.content,
    this.isError = false,
  });

  final AssistantMessageRole role;
  final String content;
  final bool isError;

  Map<String, String> toHistoryItem() => {
        'role': role == AssistantMessageRole.user ? 'user' : 'assistant',
        'content': content,
      };
}
