import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/camera_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyCameraSettings = 'camera_settings';

class CameraSettingsProvider extends ChangeNotifier {
  CameraSettings? _settings;
  bool _loaded = false;

  CameraSettings? get settings => _settings;
  bool get hasValidSettings => _settings != null && _settings!.isValid;
  String? get rtspUrl => hasValidSettings ? _settings!.rtspUrl : null;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyCameraSettings);
    if (json != null) {
      try {
        _settings = CameraSettings.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
      } catch (_) {
        _settings = null;
      }
    } else {
      _settings = null;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(CameraSettings newSettings) async {
    _settings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyCameraSettings,
      jsonEncode(newSettings.toJson()),
    );
    notifyListeners();
  }

  Future<void> clear() async {
    _settings = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCameraSettings);
    notifyListeners();
  }
}
