import 'package:flutter/foundation.dart';
import '../models/expression_type.dart';

class CameraProvider extends ChangeNotifier {
  ExpressionType? _currentExpression;
  
  ExpressionType? get currentExpression => _currentExpression;
  
  Future<void> updateExpression(ExpressionType type) async {
    _currentExpression = type;
    notifyListeners();
    
    // Simulate hardware communication delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // In a real app, this would send a signal to the 2.8-inch screen hardware
    debugPrint('Expression updated to hardware: ${type.name}');
  }
  
  void reset() {
    _currentExpression = null;
    notifyListeners();
  }
}

