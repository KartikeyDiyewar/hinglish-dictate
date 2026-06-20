import 'package:flutter/services.dart';

/// Clipboard utility — mirror of paste.py from the original.
class ClipboardService {
  ClipboardService._();

  /// Copy text to system clipboard.
  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Get current clipboard text.
  static Future<String> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text ?? '';
  }
}
