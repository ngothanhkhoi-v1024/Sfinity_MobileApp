import 'package:flutter/material.dart';

import '../../core/i18n/app_text.dart';
import '../../core/services/speech_input_service.dart';
import '../../core/theme/app_colors.dart';

/// Nút micro / xóa cho ô tìm kiếm — chuyển giọng nói thành văn bản.
class VoiceSearchSuffix extends StatefulWidget {
  const VoiceSearchSuffix({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.iconColor,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final Color? iconColor;

  @override
  State<VoiceSearchSuffix> createState() => _VoiceSearchSuffixState();
}

class _VoiceSearchSuffixState extends State<VoiceSearchSuffix> {
  final _speech = SpeechInputService.instance;
  bool _available = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _initSpeech();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    if (_listening) _speech.stop();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize();
    if (!mounted) return;
    setState(() => _available = ok && _speech.isAvailable);
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
  }

  Future<void> _toggleVoice() async {
    final l10n = context.l10n;
    final localeId = _speech.localeIdFor(Localizations.localeOf(context));

    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (!_available) {
      _showMessage(l10n.voiceSearchUnavailable);
      return;
    }

    final granted = await _speech.ensureMicrophonePermission();
    if (!granted) {
      if (!mounted) return;
      _showMessage(l10n.voiceSearchPermissionDenied);
      return;
    }

    if (!mounted) return;
    setState(() => _listening = true);

    final started = await _speech.startListening(
      localeId: localeId,
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;

        widget.controller.text = text;
        widget.controller.selection = TextSelection.collapsed(offset: text.length);
        widget.onChanged(text);

        if (result.finalResult) {
          if (mounted) setState(() => _listening = false);
          widget.onSubmitted?.call(text);
        }
      },
    );

    if (!started && mounted) {
      setState(() => _listening = false);
      _showMessage(l10n.voiceSearchUnavailable);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = widget.iconColor ?? AppColors.muted(context);
    final primary = AppColors.primaryOf(context);
    final hasText = widget.controller.text.isNotEmpty;

    if (_listening) {
      return IconButton(
        tooltip: context.l10n.voiceSearchListening,
        onPressed: _toggleVoice,
        icon: Icon(Icons.mic_rounded, color: Theme.of(context).colorScheme.error),
        splashRadius: 18,
      );
    }

    if (hasText) {
      return IconButton(
        tooltip: context.l10n.clearSearch,
        onPressed: _clear,
        icon: Icon(Icons.close_rounded, size: 20, color: muted),
        splashRadius: 18,
      );
    }

    if (!_available) return const SizedBox.shrink();

    return IconButton(
      tooltip: context.l10n.voiceSearch,
      onPressed: _toggleVoice,
      icon: Icon(Icons.mic_none_rounded, size: 22, color: primary),
      splashRadius: 18,
    );
  }
}
