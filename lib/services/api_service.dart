import 'dart:convert';
import 'package:http/http.dart' as http;

import 'app_config.dart';
import 'storage_service.dart';

/// Gemini API-based Hinglish speech-to-text service.
/// Mirrors gemini_transcriber.py from the original desktop app.
class ApiService {
  ApiService._();
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  /// Transcribe audio bytes via Gemini API.
  /// Uses the stored API key and model selection.
  Future<String> transcribeAudio({
    required List<int> audioBytes,
    String? apiKey,
    String? model,
  }) async {
    final storage = await StorageService.init();
    final key = apiKey ?? storage.apiKey;
    if (key == null || key.isEmpty) {
      throw MissingApiKeyException('API key not set. Add it in Settings.');
    }

    final selectedModel = model ?? storage.selectedModel;
    final url = '${AppConfig.geminiBaseUrl}/$selectedModel:generateContent?key=$key';

    final base64Audio = base64Encode(audioBytes);
    final prompt = AppConfig.transcriptionPrompt;

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '$prompt\n\nAudio (base64): $base64Audio'},
            {
              'inline_data': {
                'mime_type': 'audio/wav',
                'data': base64Audio,
              }
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 1024,
      },
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      try {
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        return text?.trim() ?? '';
      } catch (_) {
        throw TranscriptionException('Unexpected API response format.');
      }
    } else if (response.statusCode == 429) {
      throw QuotaExceededException('Gemini API quota exceeded. Try later or change model.');
    } else if (response.statusCode == 400) {
      final errBody = jsonDecode(response.body);
      final msg = errBody['error']?['message'] ?? 'Bad request';
      throw TranscriptionException('API Error: $msg');
    } else {
      throw TranscriptionException('API Error ${response.statusCode}');
    }
  }
}

class MissingApiKeyException implements Exception {
  final String message;
  MissingApiKeyException(this.message);
  @override
  String toString() => message;
}

class TranscriptionException implements Exception {
  final String message;
  TranscriptionException(this.message);
  @override
  String toString() => message;
}

class QuotaExceededException implements Exception {
  final String message;
  QuotaExceededException(this.message);
  @override
  String toString() => message;
}
