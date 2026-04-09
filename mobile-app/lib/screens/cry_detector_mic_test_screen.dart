import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../services/cry_classifier.dart';
import '../services/spectrogram_processor.dart';

class CryDetectorMicTestScreen extends StatefulWidget {
  const CryDetectorMicTestScreen({super.key});

  @override
  State<CryDetectorMicTestScreen> createState() => _CryDetectorMicTestScreenState();
}

class _CryDetectorMicTestScreenState extends State<CryDetectorMicTestScreen> {
  final CryClassifier _classifier = CryClassifier();
  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription<Uint8List>? _micSub;
  Timer? _timer;

  // Keep a rolling buffer of recent PCM bytes (16-bit, little-endian).
  final List<int> _pcm = <int>[];

  bool _running = false;
  bool _modelLoaded = false;
  String? _error;

  DateTime? _lastInferAt;
  double? _lastProbCry;
  bool? _lastIsCrying;

  static const int _sampleRate = SpectrogramProcessor.sampleRate; // 16000
  static const int _bytesPerSample = 2; // pcm_s16le
  static const int _windowSeconds = 1; // model expects 1s
  static const int _inferEverySeconds = 5;

  int get _windowBytes => _sampleRate * _windowSeconds * _bytesPerSample; // 32000
  int get _maxKeepBytes => _windowBytes * 6; // keep ~6 seconds for safety

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _classifier.load();
    if (!mounted) return;
    setState(() {
      _modelLoaded = _classifier.isLoaded;
    });
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
    });

    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      setState(() {
        _error = 'Chưa có quyền microphone. Hãy cấp quyền mic và thử lại.';
      });
      return;
    }

    if (!_classifier.isLoaded) {
      await _classifier.load();
    }

    if (!mounted) return;

    _pcm.clear();
    _lastInferAt = null;
    _lastProbCry = null;
    _lastIsCrying = null;

    try {
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );

      _micSub?.cancel();
      _micSub = stream.listen(
        (chunk) {
          if (!_running) return;
          if (chunk.isEmpty) return;
          _pcm.addAll(chunk);
          if (_pcm.length > _maxKeepBytes) {
            _pcm.removeRange(0, _pcm.length - _maxKeepBytes);
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _error = 'Lỗi stream mic: $e';
            _running = false;
          });
        },
      );

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: _inferEverySeconds), (_) {
        _inferOnce();
      });

      setState(() {
        _running = true;
        _modelLoaded = _classifier.isLoaded;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể bật mic: $e';
        _running = false;
      });
      await _safeStopRecorder();
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    await _micSub?.cancel();
    _micSub = null;
    await _safeStopRecorder();
    if (!mounted) return;
    setState(() {
      _running = false;
    });
  }

  Future<void> _safeStopRecorder() async {
    try {
      await _recorder.stop();
    } catch (_) {
      // ignore
    }
  }

  void _inferOnce() {
    if (!_running) return;
    if (!_classifier.isLoaded) return;
    if (_pcm.length < _windowBytes) return;

    final start = _pcm.length - _windowBytes;
    final window = Uint8List.fromList(_pcm.sublist(start));

    final prob = _classifier.predict(window);
    if (!mounted) return;

    final now = DateTime.now();
    final isCrying = prob == null ? null : prob >= 0.5;
    if (isCrying == true) {
      debugPrint('[CRY_TEST][${now.toIso8601String()}] CRYING prob=${prob!.toStringAsFixed(4)}');
    }

    setState(() {
      _lastInferAt = now;
      _lastProbCry = prob;
      _lastIsCrying = isCrying;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _micSub?.cancel();
    _safeStopRecorder();
    _recorder.dispose();
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final statusText = _running ? 'Đang ghi âm mic' : 'Đang dừng';
    final modelText = _modelLoaded ? 'Model: OK' : 'Model: chưa load/không có file';

    final last =
        _lastInferAt == null ? 'Chưa chạy inference' : 'Lần cuối: ${_lastInferAt!.toLocal()}';

    String result;
    if (_lastProbCry == null) {
      result = 'Kết quả: —';
    } else {
      final p = (_lastProbCry! * 100).toStringAsFixed(1);
      result = 'Kết quả: ${_lastIsCrying == true ? 'CRYING' : 'NOISE'} ($p%)';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Baby Cry (Microphone)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusText, style: t.titleMedium),
            const SizedBox(height: 8),
            Text(modelText, style: t.bodyMedium),
            const SizedBox(height: 8),
            Text('Cửa sổ nhận diện: 1s @16kHz, chạy mỗi ${_inferEverySeconds}s', style: t.bodySmall),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: t.bodyMedium?.copyWith(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result, style: t.titleMedium),
                  const SizedBox(height: 6),
                  Text(last, style: t.bodySmall),
                  const SizedBox(height: 6),
                  Text('Buffer: ${_pcm.length} bytes', style: t.bodySmall),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _running ? _stop : _start,
                icon: Icon(_running ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(_running ? 'Stop test' : 'Start test'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _running ? _inferOnce : null,
                child: const Text('Infer ngay (manual)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

