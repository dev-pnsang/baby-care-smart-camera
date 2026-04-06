# Model TFLite nhận diện tiếng khóc

Đặt file model vào đây để app dùng AI phân biệt **khóc** vs **hét/ồn** (audio từ RTSP camera).

## Model mặc định: Edge Impulse (tflite_learn_916019_5.tflite)

App **đang dùng** model Edge Impulse với pipeline:

- **File:** `tflite_learn_916019_5.tflite`
- **Input:** Spectrogram INT8 `[1, 6435]` (PCM 1s 16kHz → spectrogram → quantize, xem `lib/services/spectrogram_processor.dart`).
- **Output:** 2 class INT8 (crying, noise); app tính xác suất khóc qua softmax.

Tham số DSP (theo `docs/BABY_CRY_DETECTOR_MODEL.md`): frame 20ms, stride 10ms, FFT 128, noise_floor -52 dB, scale/zeropoint như trong doc.

Nếu chưa có file, app vẫn chạy và dùng logic mức âm (RMS) thay thế.

## (Tùy chọn) Raw PCM

Nếu muốn dùng model raw PCM thay vì Edge Impulse, cần chỉnh lại `CryClassifier` và đặt `baby_cry.tflite` với input `[1, 32000]` float, output xác suất khóc.
