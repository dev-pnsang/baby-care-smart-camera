import 'package:flutter/foundation.dart';
import '../models/expression_type.dart';

class CameraProvider extends ChangeNotifier {
  ExpressionType? _currentExpression;

  /// URL RTSP lấy từ CameraSettingsProvider khi có cấu hình.
  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  ExpressionType? get currentExpression => _currentExpression;

  void setStreamingStatus(bool status) {
    _isStreaming = status;
    notifyListeners();
  }

  static ExpressionType _typeForChannel(String raw) {
    final id = raw.toLowerCase().trim();
    switch (id) {
      case 'happy':
      case 'vui_mung':
        return ExpressionType.happy;
      case 'sad':
        return ExpressionType.sad;
      case 'surprised':
      case 'to_mo':
      case 'nong_nuc':
        return ExpressionType.surprised;
      case 'sleepy':
      case 'buon_ngu':
        return ExpressionType.sleepy;
      case 'playful':
      case 'ham_mo':
        return ExpressionType.playful;
      case 'calm':
      case 'auto':
      case 'tu_dong':
      case 'thu_gian':
        return ExpressionType.calm;
      case 'lanh_leo':
        return ExpressionType.sad;
      case 'lo_so':
        return ExpressionType.sad;
      default:
        return ExpressionType.happy;
    }
  }

  /// Updates the expression on the camera's 2.8-inch screen and plays corresponding sound
  Future<void> notifyHardware(String expressionID) async {
    final expression = _typeForChannel(expressionID);

    _currentExpression = expression;
    notifyListeners();

    // Simulate hardware communication delay
    await Future.delayed(const Duration(milliseconds: 300));

    // In a real app, this would send a signal to the 2.8-inch screen hardware
    debugPrint('Expression updated to hardware: ${expression.name}');

    // Trigger sound effect for the camera's speaker
    await _playSoundEffect(expression);
  }

  /// Plays the corresponding sound effect for the expression
  Future<void> _playSoundEffect(ExpressionType type) async {
    // In a real app, this would send a command to the camera's speaker
    final soundMap = {
      ExpressionType.happy: 'giggle',
      ExpressionType.sad: 'whimper',
      ExpressionType.surprised: 'gasp',
      ExpressionType.sleepy: 'yawn',
      ExpressionType.playful: 'laugh',
      ExpressionType.calm: 'coo',
    };

    final sound = soundMap[type] ?? 'giggle';
    debugPrint('Playing sound effect: $sound');

    // Simulate sound playback delay
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> updateExpression(ExpressionType type) async {
    _currentExpression = type;
    notifyListeners();

    // Simulate hardware communication delay
    await Future.delayed(const Duration(milliseconds: 300));

    // In a real app, this would send a signal to the 2.8-inch screen hardware
    debugPrint('Expression updated to hardware: ${type.name}');

    // Also play sound effect
    await _playSoundEffect(type);
  }

  void reset() {
    _currentExpression = null;
    notifyListeners();
  }
}
