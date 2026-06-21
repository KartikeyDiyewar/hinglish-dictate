import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import '../services/overlay_service.dart';
import '../services/speech_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/clipboard_service.dart';
import '../services/app_config.dart';
import '../widgets/recording_indicator.dart';
import 'settings_screen.dart';

/// Main home screen — acts as the Controller from the original desktop app.
/// Manages lifecycle: permissions → overlay → recording → transcription → clipboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OverlayService _overlay = OverlayService();
  final SpeechService _speech = SpeechService();
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  bool _permissionsGranted = false;
  bool _apiKeySet = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _transcribedText = '';
  String? _errorMessage;

  StreamSubscription<String>? _speechSub;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await StorageService.init();
    await _checkPermissions();
    await _checkApiKey();

    if (_permissionsGranted && mounted) {
      _overlay.init(context);
    }
  }

  Future<void> _checkPermissions() async {
    final mic = await Permission.microphone.request();
    final overlay = await Permission.systemAlertWindow.request();
    final notification = await Permission.notification.request();

    setState(() {
      _permissionsGranted = mic.isGranted;
    });
  }

  Future<void> _checkApiKey() async {
    final hasKey = _storage.apiKey != null && _storage.apiKey!.isNotEmpty;
    setState(() => _apiKeySet = hasKey);
  }

  /// Called when the floating overlay button is tapped.
  void _onRecordToggle() {
    if (!_apiKeySet) {
      _showSnackBar('Please set your Gemini API key in Settings first.');
      return;
    }
    if (!_permissionsGranted) {
      _showSnackBar('Microphone permission required.');
      return;
    }

    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _speech.initialize()) {
      _showSnackBar('Speech recognition engine failed to initialize.');
      return;
    }

    // Haptic feedback
    if (_storage.vibrateOnStart && await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }

    setState(() {
      _isRecording = true;
      _transcribedText = '';
      _errorMessage = null;
    });
    _overlay.setRecording(true);

    final stream = _speech.startListening(
      onDone: () => _onRecordingDone(),
    );

    _speechSub = stream.listen(
      (partial) {
        setState(() => _transcribedText = partial);
      },
      onError: (error) {
        setState(() {
          _isRecording = false;
          _errorMessage = 'Speech error: $error';
        });
      },
    );
  }

  Future<void> _stopRecording() async {
    await _speech.stopListening();
    await _speechSub?.cancel();
    _onRecordingDone();
  }

  Future<void> _onRecordingDone() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });
    _overlay.setRecording(false);

    // The final text is already captured from the speech stream (_transcribedText)
    // Copy to clipboard
    if (_transcribedText.isNotEmpty) {
      await ClipboardService.copy(_transcribedText);
      if (mounted) {
        _showSnackBar('✅ Text copied to clipboard');
      }
    }

    setState(() => _isProcessing = false);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _speechSub?.cancel();
    _overlay.dispose();
    _speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hinglish Dictate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _checkApiKey();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Recording indicator
              if (_isRecording) const RecordingIndicator(),

              const SizedBox(height: 24),

              // Main record button
              GestureDetector(
                onTap: _onRecordToggle,
                child: AnimatedContainer(
                  duration: AppConfig.animationDuration,
                  width: _isRecording ? 100 : 80,
                  height: _isRecording ? 100 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Colors.red
                        : theme.colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: _isRecording
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status text
              Text(
                _isProcessing
                    ? 'Processing…'
                    : _isRecording
                        ? 'Listening… Tap again to stop'
                        : 'Tap mic to start dictation',
                style: theme.textTheme.bodyLarge,
              ),

              if (!_apiKeySet) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                    _checkApiKey();
                  },
                  icon: const Icon(Icons.warning_amber),
                  label: const Text('Set API Key in Settings'),
                ),
              ],

              const SizedBox(height: 24),

              // Transcribed text display
              if (_transcribedText.isNotEmpty)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transcribed:',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _transcribedText,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy',
                              onPressed: () {
                                ClipboardService.copy(_transcribedText);
                                _showSnackBar('✅ Copied!');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Clear',
                              onPressed: () =>
                                  setState(() => _transcribedText = ''),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Error display
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: _permissionsGranted
          ? FloatingActionButton.small(
              onPressed: _onRecordToggle,
              tooltip: _isRecording ? 'Stop' : 'Record',
              backgroundColor:
                  _isRecording ? Colors.red : theme.colorScheme.primary,
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
