# Nhận diện tiếng khóc từ camera (RTSP)

## Nguồn âm thanh

- **Chỉ dùng audio từ luồng RTSP của camera.** Không dùng microphone — dự án phát triển tính năng nhận diện từ camera.
- App lấy âm bằng **FFmpegKit**: mỗi 4 giây trích ~2s audio từ RTSP (AAC → PCM 16kHz mono), tính RMS → mức 0–100, cập nhật `BabyStatusProvider`. Banner "Bé đang khóc!" hiển thị khi `isCrying == true`.

## Phân biệt hét lớn vs khóc

- **Hiện tại:** Logic chỉ dựa vào **mức âm (volume)** và ngưỡng sustained. **Không phân biệt** được tiếng hét lớn và tiếng khóc — cả hai đều là âm thanh lớn nên có thể báo nhầm.
- **Để phân biệt:** Cần model AI (ví dụ TFLite) **phân loại âm thanh** (khóc / hét / bình thường), chạy trên **cùng đoạn audio** đã trích từ RTSP (file WAV tạm trong `NoiseDetectorService`), **không dùng microphone**.

## Đã tích hợp TFLite (khóc vs hét/ồn)

1. **CryClassifier** (`lib/services/cry_classifier.dart`): load `assets/models/baby_cry.tflite`, nhận PCM 16kHz mono (từ RTSP), chạy inference, trả về xác suất khóc hoặc null nếu không có model.
2. **NoiseDetectorService:** Mỗi chu kỳ lấy 2s audio RTSP → PCM. Nếu `CryClassifier.isCrying(pcmBytes)` != null thì dùng kết quả AI; không thì fallback logic RMS + sustained.
3. **Thêm model:** Đặt file `baby_cry.tflite` vào `assets/models/`. Input mẫu: `[1, 32000]` float (2s × 16kHz). Output mẫu: `[1, 1]` hoặc `[1, 2]` (xác suất khóc). Chi tiết xem `assets/models/README.md`.
4. **Không dùng microphone:** Toàn bộ pipeline chỉ dùng audio từ RTSP camera.

## Tóm tắt

| Câu hỏi | Trả lời |
|--------|--------|
| Có dùng microphone không? | **Không.** Chỉ dùng audio từ RTSP camera. |
| Có phân biệt hét vs khóc không? | **Chưa.** Hiện chỉ theo mức âm. Muốn phân biệt thì cần model AI chạy trên audio RTSP. |
