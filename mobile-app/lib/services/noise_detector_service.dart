import 'dart:async';
import 'dart:math';
import '../providers/baby_status_provider.dart';

class NoiseDetectorService {
  final BabyStatusProvider babyStatusProvider;
  Timer? _timer;
  final Random _random = Random();
  
  NoiseDetectorService(this.babyStatusProvider);
  
  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // Simulate sound level detection (45-85 dB range)
      double baseLevel = 45.0;
      double variation = _random.nextDouble() * 40.0;
      
      // Occasionally spike to simulate crying
      if (_random.nextDouble() < 0.15) {
        variation = 30.0 + (_random.nextDouble() * 20.0);
      }
      
      double currentDB = baseLevel + variation;
      babyStatusProvider.updateSoundLevel(currentDB);
    });
  }
  
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }
  
  void dispose() {
    stopMonitoring();
  }
}

