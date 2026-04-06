import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

/// Tham số DSP spectrogram theo BABY_CRY_DETECTOR_MODEL.md (Edge Impulse).
/// PCM 16kHz 1s → spectrogram (frame 20ms, stride 10ms, FFT 128, noise_floor -52 dB) → 6435 float → quantize INT8.
class SpectrogramProcessor {
  static const int sampleRate = 16000;
  static const int samplesPerSecond = 16000;
  /// Frame 20 ms = 320 mẫu, stride 10 ms = 160 mẫu, FFT 128.
  /// Mỗi frame lấy 128 mẫu từ cửa sổ 320 (để khớp FFT 128) → 65 bin tần số.
  static const int frameLengthSamples = 320;
  static const int frameStrideSamples = 160;
  static const int fftSize = 128;
  static const int fftBins = 65; // fftSize/2 + 1
  static const int noiseFloorDb = -52;
  static const int expectedFrames = 99; // (16000 - 320) / 160 + 1
  static const int expectedFeatures = 6435; // expectedFrames * fftBins

  /// Scale/zeropoint cho input model (BABY_CRY_DETECTOR_MODEL.md).
  static const double inputScale = 0.003921568859368563;
  static const int inputZeroPoint = -128;

  final FFT _fft = FFT(fftSize);
  final List<double> _hanning = _buildHanning(fftSize);

  static List<double> _buildHanning(int n) {
    final w = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      w[i] = 0.5 * (1 - math.cos(2 * math.pi * i / (n - 1)));
    }
    return w;
  }

  /// Chuẩn hóa dB về [0,1] theo noise_floor rồi quantize INT8.
  static int _quantize(double normalized, {double scale = inputScale, int zeroPoint = inputZeroPoint}) {
    final q = (normalized / scale + zeroPoint).round();
    if (q < -128) {
      return -128;
    }
    if (q > 127) {
      return 127;
    }
    return q;
  }

  /// PCM float -1..1, 16000 mẫu (1 giây 16kHz). Trả về 6435 giá trị INT8 (shape [1, 6435]).
  /// Pipeline: frame → Hanning → FFT 128 → magnitude → dB → clamp noise_floor → normalize [0,1] → quantize.
  Int8List pcmToSpectrogramInt8(List<double> pcm) {
    if (pcm.length < samplesPerSecond) {
      final padded = List<double>.filled(samplesPerSecond, 0.0);
      for (int i = 0; i < pcm.length; i++) {
        padded[i] = pcm[i];
      }
      return _computeSpectrogram(padded);
    }
    return _computeSpectrogram(pcm.sublist(0, samplesPerSecond));
  }

  Int8List _computeSpectrogram(List<double> pcm) {
    final out = Int8List(expectedFeatures);
    int outIdx = 0;
    final frame = List<double>.filled(fftSize, 0.0);

    for (int f = 0; f < expectedFrames; f++) {
      final start = f * frameStrideSamples;
      for (int i = 0; i < fftSize; i++) {
        final srcIdx = start + i;
        frame[i] = srcIdx < pcm.length ? pcm[srcIdx] * _hanning[i] : 0.0;
      }
      final freq = _fft.realFft(frame);
      final conjugated = freq.discardConjugates();
      final mags = conjugated.magnitudes();

      for (int b = 0; b < fftBins; b++) {
        final magnitude = mags[b];
        final power = magnitude * magnitude;
        const eps = 1e-12;
        double db = 10.0 * math.log(power + eps) / math.ln10;
        if (db < noiseFloorDb) db = noiseFloorDb.toDouble();
        final normalized = (db - noiseFloorDb) / (-noiseFloorDb);
        out[outIdx++] = _quantize(normalized.clamp(0.0, 1.0));
      }
    }
    return out;
  }

  /// Chuyển PCM 16-bit (Uint8List, little-endian) thành List<double> -1..1, tối đa 16000 mẫu.
  static List<double> pcmBytesToFloat(Uint8List bytes, {int maxSamples = samplesPerSecond}) {
    final byteData = ByteData.sublistView(bytes);
    final sampleCount = math.min(bytes.length ~/ 2, maxSamples);
    final floats = List<double>.filled(sampleCount, 0.0);
    for (int i = 0; i < sampleCount; i++) {
      final s = byteData.getInt16(i * 2, Endian.little);
      floats[i] = (s / 32768.0).clamp(-1.0, 1.0);
    }
    if (floats.length < maxSamples) {
      final padded = List<double>.filled(maxSamples, 0.0);
      for (int i = 0; i < floats.length; i++) {
        padded[i] = floats[i];
      }
      return padded;
    }
    return floats;
  }
}
