import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'app_config.dart';

/// Manages microphone recording and on-device speech recognition.
/// Falls back to Gemini API for Hinglish-specific transcription.
class SpeechService {
  SpeechService._();
  static final SpeechService _instance = SpeechService._();
  factory SpeechService() => _instance;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  // For raw audio recording (Gemini path)
  List<int>? _recordedBytes;
  Timer? _silenceTimer;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  /// Initialize speech recognition engine.
  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    return _isAvailable;
  }

  /// Start listening. Returns a stream of partial results.
  Stream<String> startListening({
    String locale = AppConfig.defaultHinglishLocale,
    void Function()? onDone,
  }) {
    _isListening = true;

    final controller = StreamController<String>();
    _speech.listen(
      onResult: (result) {
        controller.add(result.recognizedWords);
        if (result.finalResult) {
          _isListening = false;
          onDone?.call();
        }
      },
      localeId: locale,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: true,
      partialResults: true,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );

    return controller.stream;
  }

  /// Stop listening.
  Future<String> stopListening() async {
    _isListening = false;
    await _speech.stop();
    return _speech.lastRecognizedWords ?? '';
  }

  /// Cancel current listening session.
  Future<void> cancelListening() async {
    _isListening = false;
    await _speech.cancel();
  }

  void dispose() {
    _speech.cancel();
  }
}
