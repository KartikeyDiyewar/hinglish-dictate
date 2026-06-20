import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/storage_service.dart';
import '../services/app_config.dart';

/// Settings screen — API key input + model selection + preferences.
/// Mirrors dictate_ui.py from the original desktop app.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _storage = StorageService();
  String _selectedModel = AppConfig.defaultModel;
  bool _autoPaste = true;
  bool _vibrateOnStart = true;
  bool _overlayEnabled = true;
  bool _apiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _apiKeyController.text = _storage.apiKey ?? '';
      _selectedModel = _storage.selectedModel;
      _autoPaste = _storage.autoPaste;
      _vibrateOnStart = _storage.vibrateOnStart;
      _overlayEnabled = _storage.overlayEnabled;
    });
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      await _storage.clearApiKey();
    } else {
      await _storage.setApiKey(key);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(key.isEmpty
              ? 'API key cleared'
              : 'API key saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: () {
              _saveApiKey();
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── API Key Section ──
          Text('Gemini API Key', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _apiKeyController,
            obscureText: !_apiKeyVisible,
            decoration: InputDecoration(
              hintText: 'Enter your Gemini API key',
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _apiKeyVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _apiKeyVisible = !_apiKeyVisible),
                  ),
                  IconButton(
                    icon: const Icon(Icons.paste),
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        _apiKeyController.text = data!.text!;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                onPressed: _saveApiKey,
                icon: const Icon(Icons.save),
                label: const Text('Save Key'),
              ),
              TextButton.icon(
                onPressed: () {
                  _apiKeyController.clear();
                  _storage.clearApiKey();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Model Selection ──
          Text('Model', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedModel,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: AppConfig.modelOptions.map((model) {
              return DropdownMenuItem(value: model, child: Text(model));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedModel = value);
                _storage.setSelectedModel(value);
              }
            },
          ),
          const SizedBox(height: 24),

          // ── Preferences ──
          Text('Preferences', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Auto-copy to clipboard'),
            subtitle: const Text('Transcribed text is automatically copied'),
            value: _autoPaste,
            onChanged: (value) {
              setState(() => _autoPaste = value);
              _storage.setAutoPaste(value);
            },
          ),
          SwitchListTile(
            title: const Text('Vibrate on recording'),
            subtitle: const Text('Haptic feedback when recording starts'),
            value: _vibrateOnStart,
            onChanged: (value) {
              setState(() => _vibrateOnStart = value);
              _storage.setVibrateOnStart(value);
            },
          ),
          SwitchListTile(
            title: const Text('Floating overlay'),
            subtitle: const Text('Show mic button when keyboard is active'),
            value: _overlayEnabled,
            onChanged: (value) {
              setState(() => _overlayEnabled = value);
              _storage.setOverlayEnabled(value);
            },
          ),
          const SizedBox(height: 32),

          // ── Help ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to get an API key?',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    '1. Go to aistudio.google.com\n'
                    '2. Click "Get API Key"\n'
                    '3. Create a new key\n'
                    '4. Copy and paste it here',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
