import 'dart:math' show exp;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'spectrogram_processor.dart';

/// Classifier TFLite chạy trên PCM từ RTSP để phân biệt khóc vs hét/ồn.
/// Nguồn âm: chỉ audio từ camera (RTSP), không dùng microphone.
///
/// Dùng model Edge Impulse `tflite_learn_916019_5.tflite`: input spectrogram INT8 [1, 6435],
/// output 2 class INT8 (crying, noise). Pipeline: PCM 1s 16kHz → spectrogram → quantize INT8 → TFLite.
/// Nếu không có file hoặc load lỗi, [predict] trả về null.
const String _modelAsset = 'assets/models/tflite_learn_916019_5.tflite';
const double _defaultCryThreshold = 0.5;

/// Scale/zeropoint output model (BABY_CRY_DETECTOR_MODEL.md).
const double _outputScale = 0.00390625;
const int _outputZeroPoint = -128;

class CryClassifier {
  Interpreter? _interpreter;
  final SpectrogramProcessor _spectrogram = SpectrogramProcessor();
  bool _loading = false;
  bool _loaded = false;

  /// Load model từ asset. Gọi một lần (ví dụ khi app start hoặc khi bắt đầu monitor).
  Future<void> load() async {
    if (_loading || (_loaded && _interpreter != null)) return;
    _loading = true;
    try {
      _interpreter = await Interpreter.fromAsset(_modelAsset);
      _loaded = true;
    } on PlatformException catch (_) {
      _interpreter?.close();
      _interpreter = null;
    } catch (_) {
      _interpreter?.close();
      _interpreter = null;
    } finally {
      _loading = false;
    }
  }

  bool get isLoaded => _interpreter != null;

  /// PCM 16-bit little-endian (không có WAV header), 16kHz mono. Cần tối thiểu 1 giây (32000 byte).
  /// App có thể truyền 2s từ RTSP; classifier chỉ dùng 1s đầu.
  /// Trả về xác suất "khóc" (0..1), hoặc null nếu không dùng được model.
  double? predict(Uint8List pcmBytes, {double cryThreshold = _defaultCryThreshold}) {
    final interp = _interpreter;
    if (interp == null) return null;

    try {
      final pcmFloat = SpectrogramProcessor.pcmBytesToFloat(pcmBytes);
      final spectrogramInt8 = _spectrogram.pcmToSpectrogramInt8(pcmFloat);

      // Input shape [1, 6435] INT8
      final input = [spectrogramInt8];
      final output = [List<int>.filled(2, 0)];

      interp.run(input, output);

      final cryRaw = output[0][0];
      final noiseRaw = output[0][1];
      final cryScore = (cryRaw - _outputZeroPoint) * _outputScale;
      final noiseScore = (noiseRaw - _outputZeroPoint) * _outputScale;
      final probCry = _softmaxCry(cryScore, noiseScore);
      return probCry.clamp(0.0, 1.0);
    } catch (_) {
      return null;
    }
  }

  /// Coi output là logits, tính xác suất class "crying".
  static double _softmaxCry(double cryLogit, double noiseLogit) {
    final maxL = cryLogit > noiseLogit ? cryLogit : noiseLogit;
    final ec = exp(cryLogit - maxL);
    final en = exp(noiseLogit - maxL);
    return ec / (ec + en);
  }

  /// Trả về true nếu model dự đoán "khóc" (probability >= threshold).
  bool? isCrying(Uint8List pcmBytes, {double cryThreshold = _defaultCryThreshold}) {
    final p = predict(pcmBytes, cryThreshold: cryThreshold);
    if (p == null) return null;
    return p >= cryThreshold;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loaded = false;
  }
}
