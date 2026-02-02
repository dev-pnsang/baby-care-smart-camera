import 'package:flutter/foundation.dart';

class BabyStatusProvider extends ChangeNotifier {
  bool _isCrying = false;
  double _soundLevel = 45.0; // dB
  
  bool get isCrying => _isCrying;
  double get soundLevel => _soundLevel;
  
  void updateSoundLevel(double db) {
    _soundLevel = db;
    _isCrying = db > 70.0;
    notifyListeners();
  }
  
  void setCryingStatus(bool crying) {
    _isCrying = crying;
    notifyListeners();
  }
  
  void reset() {
    _isCrying = false;
    _soundLevel = 45.0;
    notifyListeners();
  }
}

