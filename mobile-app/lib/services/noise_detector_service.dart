import 'dart:async';
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

  NoiseDetectorService(this.babyStatusProvider, {CryClassifier? cryClassifier})
      : cryClassifier = cryClassifier ?? CryClassifier();

  void startMonitoring(String rtspUrl) {
    _rtspUrl = rtspUrl;
    _timer?.cancel();
    cryClassifier.load().then((_) {
      _sampleOnce();
    });
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
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
      final aiCrying = cryClassifier.isCrying(Uint8List.fromList(pcmBytes));
      final bool isCrying;
      if (aiCrying != null) {
        isCrying = aiCrying;
      } else {
        if (level > _cryThreshold) {
          _consecutiveHigh++;
        } else {
          _consecutiveHigh = 0;
        }
        isCrying = _consecutiveHigh >= _sustainedSamplesForCry;
      }

      babyStatusProvider.updateSoundLevel(level);
      babyStatusProvider.setCryingStatus(isCrying);
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
  }

  void dispose() {
    stopMonitoring();
    cryClassifier.dispose();
  }
}

