import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/baby_status_provider.dart';
import 'cry_classifier.dart';

/// Đo mức âm thanh thực tế từ luồng RTSP (camera) bằng FFmpegKit.
/// Lưu ý: Không dùng microphone — dự án nhận diện từ camera, nguồn âm duy nhất là RTSP.
///
/// Mỗi chu kỳ: lấy 2s audio từ RTSP (AAC_ADTS → PCM 16kHz mono), tính RMS → mức 0–100.
/// Hiện tại chỉ dựa vào mức âm (volume), không phân biệt được hét lớn vs khóc.
/// Để phân biệt khóc / hét / bình thường cần model AI (TFLite) chạy trên chính đoạn audio RTSP này.
const double _cryThreshold = 70.0;
const int _sustainedSamplesForCry = 2;

class NoiseDetectorService {
  final BabyStatusProvider babyStatusProvider;
  final CryClassifier cryClassifier;
  Timer? _timer;
  String? _rtspUrl;
  bool _isSampling = false;
  int _consecutiveHigh = 0;
  double _cryProbThreshold = 0.6;
  double _noiseProbThreshold = 0.5;
  int _consecutiveAiCry = 0;
  int _consecutiveAiNoise = 0;
  CrySoundState _lastStableAi = CrySoundState.unknown;
  int _sampleIntervalSeconds = 5;

  NoiseDetectorService(this.babyStatusProvider, {CryClassifier? cryClassifier})
      : cryClassifier = cryClassifier ?? CryClassifier();

  /// Đổi chu kỳ lấy mẫu khi user chỉnh trong Cài đặt (giữ nguyên URL đang monitor).
  void updateSampleInterval(int sampleIntervalSeconds) {
    final sec = sampleIntervalSeconds.clamp(3, 120);
    _sampleIntervalSeconds = sec;
    if (_rtspUrl == null || _rtspUrl!.isEmpty || _timer == null) {
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: sec), (_) {
      _sampleOnce();
    });
  }

  /// Cập nhật ngưỡng AI khi user đổi trong Cài đặt (không restart timer).
  void updateCryThresholds({
    required double cryProbThreshold,
    required double noiseProbThreshold,
  }) {
    var c = cryProbThreshold.clamp(0.05, 0.99);
    var n = noiseProbThreshold.clamp(0.05, 0.99);
    if (n >= c) {
      n = c - 0.01;
    }
    if (n < 0.05) {
      n = 0.05;
    }
    _cryProbThreshold = c;
    _noiseProbThreshold = n;
  }

  void startMonitoring(
    String rtspUrl, {
    int sampleIntervalSeconds = 5,
    double cryProbThreshold = 0.6,
    double noiseProbThreshold = 0.5,
  }) {
    _rtspUrl = rtspUrl;
    _sampleIntervalSeconds = sampleIntervalSeconds.clamp(3, 120);
    _cryProbThreshold = cryProbThreshold;
    _noiseProbThreshold = noiseProbThreshold;
    _consecutiveAiCry = 0;
    _consecutiveAiNoise = 0;
    _lastStableAi = CrySoundState.unknown;
    _timer?.cancel();
    cryClassifier.load().then((_) {
      _sampleOnce();
    });
    _timer = Timer.periodic(Duration(seconds: _sampleIntervalSeconds), (_) {
      _sampleOnce();
    });
  }

  Future<void> _sampleOnce() async {
    if (_isSampling) return;
    final url = _rtspUrl;
    if (url == null || url.isEmpty) return;
    _isSampling = true;
    try {
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/rtsp_chunk_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Lấy 2 giây audio từ RTSP, không lấy video (-vn), chuyển AAC -> PCM 16kHz mono.
      final cmd =
          '-y -i "$url" -vn -acodec pcm_s16le -ar 16000 -ac 1 -t 2 "$outPath"';
      final session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        return;
      }

      final file = File(outPath);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      await file.delete().catchError((_) => file);

      // WAV PCM 16-bit có header 44 byte, bỏ qua khi tính RMS
      const wavHeader = 44;
      if (bytes.lengthInBytes < wavHeader + 4) return;
      final pcmBytes = bytes.sublist(wavHeader);
      final byteData = ByteData.sublistView(pcmBytes);
      final sampleCount = pcmBytes.length ~/ 2;
      double sumSquares = 0;
      for (int i = 0; i < sampleCount; i++) {
        final sample = byteData.getInt16(i * 2, Endian.little).toDouble();
        sumSquares += sample * sample;
      }
      final rms = sqrt(sumSquares / sampleCount);
      // Chuẩn hóa RMS về 0-100 cho UI, 70+ coi là khóc (xem BabyStatusProvider).
      final normalized = (rms / 32768.0).clamp(0.0, 1.0);
      final level = (normalized * 100).clamp(0.0, 100.0);

      // Ưu tiên AI (TFLite) nếu có model — phân biệt khóc vs hét/ồn; không thì dùng RMS + sustained
      final pcm = Uint8List.fromList(pcmBytes);
      final probCry = cryClassifier.predict(pcm);
      final CrySoundState? aiState;
      if (probCry == null) {
        aiState = null;
      } else if (probCry >= _cryProbThreshold) {
        aiState = CrySoundState.crying;
      } else if (probCry < _noiseProbThreshold) {
        // Theo yêu cầu: chỉ cần noise (probCry < 50%) thì báo ngay.
        aiState = CrySoundState.noise;
      } else {
        // Vùng không chắc chắn 50%..60%: không đổi trạng thái để tránh nhấp nháy.
        aiState = CrySoundState.unknown;
      }
      final bool isCrying;
      if (aiState != null) {
        // Rule:
        // - crying: require sustained >= 2 samples (giảm báo nhầm)
        // - noise: immediate when probCry < 50% (theo yêu cầu)
        if (aiState == CrySoundState.crying) {
          _consecutiveAiCry++;
          _consecutiveAiNoise = 0;
          if (_consecutiveAiCry >= _sustainedSamplesForCry) {
            _lastStableAi = CrySoundState.crying;
          }
        } else if (aiState == CrySoundState.noise) {
          _consecutiveAiNoise++;
          _consecutiveAiCry = 0;
          _lastStableAi = CrySoundState.noise;
        } else {
          // unknown band: decay streaks but keep last stable state
          _consecutiveAiCry = 0;
          _consecutiveAiNoise = 0;
        }

        isCrying = _lastStableAi == CrySoundState.crying;

        dev.log(
          'ai=$aiState probCry=${probCry!.toStringAsFixed(4)} '
          'stable=$_lastStableAi '
          'streakCry=$_consecutiveAiCry streakNoise=$_consecutiveAiNoise '
          'level=${level.toStringAsFixed(1)}',
          name: 'CRY_RTSP',
        );
      } else {
        if (level > _cryThreshold) {
          _consecutiveHigh++;
        } else {
          _consecutiveHigh = 0;
        }
        isCrying = _consecutiveHigh >= _sustainedSamplesForCry;
      }

      babyStatusProvider.updateSoundLevel(level);
      if (probCry != null) {
        babyStatusProvider.setCryClassification(
          _lastStableAi,
          probability: probCry,
        );
      } else {
        // Không có AI → fallback theo RMS (không phân biệt được noise/cry)
        babyStatusProvider.setCryClassification(
          isCrying ? CrySoundState.crying : CrySoundState.unknown,
          probability: null,
        );
      }
    } catch (_) {
      // Bỏ qua lỗi, lần sau thử lại.
    } finally {
      _isSampling = false;
    }
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _consecutiveHigh = 0;
    _consecutiveAiCry = 0;
    _consecutiveAiNoise = 0;
    _lastStableAi = CrySoundState.unknown;
  }

  void dispose() {
    stopMonitoring();
    cryClassifier.dispose();
  }
}

