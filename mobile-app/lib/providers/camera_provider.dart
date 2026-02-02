import 'package:flutter/foundation.dart';
import '../models/expression_type.dart';

class CameraProvider extends ChangeNotifier {
  ExpressionType? _currentExpression;
  
  ExpressionType? get currentExpression => _currentExpression;
  
  /// Updates the expression on the camera's 2.8-inch screen and plays corresponding sound
  Future<void> notifyHardware(String expressionID) async {
    // Find the expression type from ID
    final expression = ExpressionType.values.firstWhere(
      (e) => e.name.toLowerCase() == expressionID.toLowerCase(),
      orElse: () => ExpressionType.happy,
    );
    
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

