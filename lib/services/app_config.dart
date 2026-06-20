import 'package:flutter/foundation.dart';

/// Configuration constants — inspired by the original HinglishDictate.
class AppConfig {
  AppConfig._();

  // ── Speech ──
  static const String defaultLocale = 'hi-IN';
  static const String defaultHinglishLocale = 'hi-IN';
  static const double silenceTimeout = 2.0; // seconds of silence before auto-stop
  static const int maxRecordingDuration = 60; // seconds max

  // ── Gemini API ──
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String defaultModel = 'gemini-3.1-flash-lite';
  static const List<String> modelOptions = [
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash',
    'gemini-3.1-pro-preview',
  ];

  // Custom prompt for Hinglish transcription
  static const String transcriptionPrompt =
      'You are a Hinglish dictation transcriber. The user is dictating prompts '
      'they want to send to coding assistants. Transcribe the audio accurately '
      'into text, preserving the Hinglish mix. Output ONLY the transcribed text, '
      'no explanations.';

  // ── UI ──
  static const double overlaySize = 48.0;
  static const double overlayMargin = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // ── Storage keys ──
  static const String keyApiKey = 'api_key';
  static const String keySelectedModel = 'selected_model';
  static const String keyAutoPaste = 'auto_paste';
  static const String keyVibrateOnStart = 'vibrate_on_start';
  static const String keyOverlayEnabled = 'overlay_enabled';
}
