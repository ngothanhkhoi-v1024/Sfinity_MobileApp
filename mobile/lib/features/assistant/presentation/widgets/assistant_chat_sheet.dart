import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/i18n/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../splash/presentation/widgets/academic_sealion_mascot.dart';
import '../../data/models/assistant_message.dart';
import 'assistant_message_bubble.dart';

class AssistantChatSheet extends StatefulWidget {
  const AssistantChatSheet({
    super.key,
    required this.contextId,
  });

  final String contextId;

  static Future<void> show(BuildContext context, {required String contextId}) {
    SfinityApp.assistantController.setContext(contextId);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.72,
          child: AssistantChatSheet(contextId: contextId),
        ),
      ),
    );
  }

  @override
  State<AssistantChatSheet> createState() => _AssistantChatSheetState();
}

class _AssistantChatSheetState extends State<AssistantChatSheet> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final ctrl = SfinityApp.assistantController;
    if (ctrl.messages.isEmpty) {
      ctrl.clearMessages();
    }
    ctrl.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    SfinityApp.assistantController.removeListener(_onControllerChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _inputCtrl.text).trim();
    if (message.isEmpty) return;
    _inputCtrl.clear();
    await SfinityApp.assistantController.send(message);
  }

  List<String> _quickSuggestions(AppLocalizations l10n) {
    return switch (widget.contextId) {
      'places' => [
          l10n.assistantQuickCheckIn,
          l10n.assistantQuickStudyNearMe,
        ],
      'documents' => [l10n.assistantQuickUploadDoc],
      'community' => [l10n.assistantQuickCreateGroup],
      'profile' => [l10n.assistantQuickSettings],
      _ => [l10n.assistantQuickExplore],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ctrl = SfinityApp.assistantController;
    final messages = ctrl.messages;
    final suggestions = _quickSuggestions(l10n);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            children: [
              const SizedBox(
                width: 52,
                height: 52,
                child: AcademicSealionMascot(size: 52),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assistantTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.title(context),
                      ),
                    ),
                    Text(
                      l10n.assistantSubtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.divider(context)),
        Expanded(
          child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            children: [
              AssistantMessageBubble(
                content: l10n.assistantWelcome,
                isUser: false,
              ),
              ...messages.map(
                (m) => AssistantMessageBubble(
                  content: m.content,
                  isUser: m.role == AssistantMessageRole.user,
                  isError: m.isError,
                ),
              ),
              if (ctrl.loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: AcademicSealionMascot(size: 28),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.assistantThinking,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted(context),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (messages.isEmpty)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: suggestions.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final label = suggestions[i];
                return ActionChip(
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  onPressed: ctrl.loading ? null : () => _send(label),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: ctrl.loading ? null : (_) => _send(),
                  decoration: InputDecoration(
                    hintText: l10n.assistantPlaceholder,
                    filled: true,
                    fillColor: AppColors.chipBg(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: ctrl.loading ? null : () => _send(),
                icon: const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
