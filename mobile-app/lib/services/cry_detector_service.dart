import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/baby_status_provider.dart';

/// Phát hiện tiếng khóc từ mức âm thanh (hiện tại từ mô phỏng / sau này có thể từ audio RTSP).
/// Khi phát hiện tiếng khóc → gọi [onCryDetected].
/// Lưu ý: Trên Flutter, audio trực tiếp từ stream RTSP chưa được expose bởi flutter_vlc_player.
/// Để nhận diện từ audio RTSP thật cần native plugin hoặc xử lý phía server.
class CryDetectorService {
  final BabyStatusProvider _babyStatusProvider;
  final VoidCallback? onCryDetected;
  Timer? _timer;
  bool _lastCryingState = false;
  bool _alertShownForCurrentEpisode = false;

  CryDetectorService(this._babyStatusProvider, {this.onCryDetected});

  void startMonitoring() {
    _timer?.cancel();
    _lastCryingState = _babyStatusProvider.isCrying;
    _alertShownForCurrentEpisode = _babyStatusProvider.isCrying;

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final isCrying = _babyStatusProvider.isCrying;
      if (isCrying && !_lastCryingState && !_alertShownForCurrentEpisode) {
        _alertShownForCurrentEpisode = true;
        onCryDetected?.call();
      }
      if (!isCrying) {
        _alertShownForCurrentEpisode = false;
      }
      _lastCryingState = isCrying;
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
