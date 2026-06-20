import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

/// Persistent key-value storage — API key, model, preferences.
/// Mirrors key_store.py from the original desktop app.
class StorageService {
  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> init() async {
    if (_instance != null) return _instance!;
    _instance = StorageService._();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  // ── API Key ──
  String? get apiKey => _prefs.getString(AppConfig.keyApiKey);
  Future<bool> setApiKey(String key) =>
      _prefs.setString(AppConfig.keyApiKey, key);
  Future<bool> clearApiKey() => _prefs.remove(AppConfig.keyApiKey);

  // ── Model Selection ──
  String get selectedModel =>
      _prefs.getString(AppConfig.keySelectedModel) ?? AppConfig.defaultModel;
  Future<bool> setSelectedModel(String model) =>
      _prefs.setString(AppConfig.keySelectedModel, model);

  // ── Preferences ──
  bool get autoPaste => _prefs.getBool(AppConfig.keyAutoPaste) ?? true;
  Future<bool> setAutoPaste(bool value) =>
      _prefs.setBool(AppConfig.keyAutoPaste, value);

  bool get vibrateOnStart => _prefs.getBool(AppConfig.keyVibrateOnStart) ?? true;
  Future<bool> setVibrateOnStart(bool value) =>
      _prefs.setBool(AppConfig.keyVibrateOnStart, value);

  bool get overlayEnabled => _prefs.getBool(AppConfig.keyOverlayEnabled) ?? true;
  Future<bool> setOverlayEnabled(bool value) =>
      _prefs.setBool(AppConfig.keyOverlayEnabled, value);
}
