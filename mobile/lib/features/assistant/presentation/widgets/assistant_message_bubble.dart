import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/assistant_action.dart';
import '../utils/assistant_action_handler.dart';
import '../../../splash/presentation/widgets/academic_sealion_mascot.dart';

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.isError = false,
    this.actions = const [],
    this.sources = const [],
  });

  final String content;
  final bool isUser;
  final bool isError;
  final List<AssistantAction> actions;
  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final bubbleColor = isUser
        ? cs.primary
        : isError
            ? cs.errorContainer
            : AppColors.card(context);
    final textColor = isUser
        ? cs.onPrimary
        : isError
            ? cs.onErrorContainer
            : AppColors.title(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: AcademicSealionMascot(size: 36),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.border(context)),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 4),
            ],
          ),
          if (!isUser && actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final action in actions)
                    ActionChip(
                      label: Text(
                        AssistantActionHandler.actionButtonLabel(context, action),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => AssistantActionHandler.handle(context, action),
                    ),
                ],
              ),
            ),
          if (!isUser && sources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Text(
                '${l10n.assistantSources}: ${sources.join(', ')}',
                style: TextStyle(fontSize: 10.5, color: AppColors.muted(context)),
              ),
            ),
        ],
      ),
    );
  }
}
