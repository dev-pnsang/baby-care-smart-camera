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

  /// [force] = true: đọc lại từ disk (dùng khi mở Cài đặt hoặc sau khi đổi model — tránh instance cũ sau hot reload).
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyCameraSettings);
    if (json != null) {
      try {
        final map = jsonDecode(json);
        if (map is Map<String, dynamic>) {
          _settings = CameraSettings.fromJson(map);
        } else {
          _settings = null;
        }
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
