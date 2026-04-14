import 'package:flutter/foundation.dart';

enum CrySoundState {
  unknown,
  crying,
  noise,
}

class BabyStatusProvider extends ChangeNotifier {
  bool _isCrying = false;
  double _soundLevel = 45.0; // dB

  CrySoundState _crySoundState = CrySoundState.unknown;
  double? _cryProbability; // 0..1 if AI available

  bool get isCrying => _isCrying;
  double get soundLevel => _soundLevel;
  CrySoundState get crySoundState => _crySoundState;
  double? get cryProbability => _cryProbability;

  void updateSoundLevel(double db) {
    _soundLevel = db;
    notifyListeners();
  }

  void setCryingStatus(bool crying) {
    _isCrying = crying;
    notifyListeners();
  }

  void setCryClassification(
    CrySoundState state, {
    double? probability,
  }) {
    _crySoundState = state;
    _cryProbability = probability;
    _isCrying = state == CrySoundState.crying;
    notifyListeners();
  }

  void reset() {
    _isCrying = false;
    _soundLevel = 45.0;
    _crySoundState = CrySoundState.unknown;
    _cryProbability = null;
    notifyListeners();
  }
}

