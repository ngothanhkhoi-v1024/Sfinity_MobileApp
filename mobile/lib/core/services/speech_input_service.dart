import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Chuyển giọng nói thành văn bản cho ô tìm kiếm.
class SpeechInputService {
  SpeechInputService._();

  static final SpeechInputService instance = SpeechInputService._();

  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;

  bool get isAvailable => _initialized && _stt.isAvailable;

  bool get isListening => _stt.isListening;

  Future<bool> initialize() async {
    if (_initialized) return _stt.isAvailable;
    _initialized = await _stt.initialize(
      onError: (error) => debugPrint('[SpeechInput] $error'),
      onStatus: (status) => debugPrint('[SpeechInput] $status'),
    );
    return _stt.isAvailable;
  }

  Future<bool> ensureMicrophonePermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  String? localeIdFor(Locale locale) {
    final tag = locale.toLanguageTag();
    if (tag == 'vi') return 'vi_VN';
    if (tag.startsWith('vi-')) return 'vi_VN';
    if (tag == 'en') return 'en_US';
    if (tag.startsWith('en-')) return 'en_US';
    return tag.replaceAll('-', '_');
  }

  Future<bool> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    String? localeId,
  }) async {
    if (!await initialize()) return false;
    if (!await ensureMicrophonePermission()) return false;
    if (_stt.isListening) await _stt.stop();

    await _stt.listen(
      onResult: onResult,
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.search,
      ),
    );
    return _stt.isListening;
  }

  Future<void> stop() => _stt.stop();

  Future<void> cancel() => _stt.cancel();
}
