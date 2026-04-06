# Dùng model Baby-Cry-Detector (firmware) trong app Flutter

## Kết luận: **Có thể dùng được**, nhưng cần thêm 2 bước

Model trong `firmware/Baby-Cry-Detector` (Edge Impulse – Mandy Madongyi) **phân biệt "crying" vs "noise"** (gồm hét, nói, nhạc, v.v.), phù hợp với nhu cầu nhận diện tiếng khóc từ camera. Để chạy trong app Flutter cần:

1. **Lấy file .tflite** (repo hiện chỉ có firmware C++, không có .tflite).
2. **Chuẩn bị input đúng format** (spectrogram INT8, không phải raw PCM).

---

## Thông số model (từ firmware)

| Mục | Giá trị |
|-----|--------|
| **Nguồn** | Edge Impulse – "Baby-cry-detector Mandy Madongyi" (project 92154) |
| **Input** | **6435 giá trị INT8** (spectrogram đã chuẩn hóa + quantize) |
| **Output** | 2 class INT8: **"crying"**, **"noise"** |
| **Audio gốc** | **1 giây**, **16 kHz**, mono |
| **DSP** | Spectrogram: frame 20 ms, stride 10 ms, FFT 128, noise_floor -52 dB |
| **Input scale/zeropoint** | scale = 0.003921568859368563, zeropoint = -128 |
| **Output scale/zeropoint** | scale = 0.00390625, zeropoint = -128 |

- **Nhãn:** `crying` (index 0), `noise` (index 1).  
- README ghi: accuracy ~93%, crying vs noise (bao gồm nói, nhạc, sủa, v.v.).

---

## Bước 1: Lấy file .tflite

Trong repo **không có** file `.tflite`, chỉ có code C++ (Arduino) với model nhúng trong `trained_model_compiled.cpp`.

Cách lấy .tflite:

1. Vào **Edge Impulse Studio** (project public):  
   https://studio.edgeimpulse.com/public/92154/latest  
2. Đăng nhập (hoặc tạo tài khoản miễn phí).  
3. Vào **Deploy** → chọn **TensorFlow Lite** → build và tải file `.tflite`.  
4. Đặt file vào `mobile-app/assets/models/` và đặt tên (ví dụ) `baby_cry.tflite`.

Nếu project không cho phép deploy, có thể dùng bản clone từ GitHub gốc (README có link) và export từ project Edge Impulse tương ứng.

---

## Bước 2: Input là spectrogram INT8, không phải PCM

Model **không** nhận raw PCM. Pipeline trong firmware:

```
PCM 16kHz, 1s (16000 samples)
  → Spectrogram (frame 20ms, stride 10ms, FFT 128)
  → Chuẩn hóa (noise_floor -52 dB)
  → Flatten → 6435 phần tử float
  → Quantize: int8 = round(float / scale + zeropoint)
  → Input TFLite: [1, 6435] INT8
```

Trong app Flutter hiện tại:

- `NoiseDetectorService` lấy **2 giây** PCM 16 kHz từ RTSP (phù hợp về sample rate).  
- Có thể cắt **1 giây** (16000 samples) từ đó.  
- Cần thêm bước: **tính spectrogram** (đúng tham số trên) → **chuẩn hóa** → **quantize INT8** → đưa vào TFLite.

Tức là **có thể dùng được** nếu:

- Có file `.tflite` (bước 1).  
- Trong app thêm lớp xử lý: PCM 1s → spectrogram (20ms/10ms, FFT 128, noise_floor -52) → flatten 6435 → quantize (scale/zeropoint như trên) → `CryClassifier` nhận **buffer INT8 6435** (hoặc mở rộng `CryClassifier` để nhận PCM và tự tính spectrogram bên trong).

---

## Tóm tắt

| Câu hỏi | Trả lời |
|--------|--------|
| Model này dùng được trong app không? | **Có**, sau khi có .tflite và chuẩn bị input spectrogram INT8 đúng format. |
| Có phân biệt khóc vs hét/ồn không? | **Có** – 2 class "crying" và "noise" (noise gồm hét, nói, nhạc, v.v.). |
| Repo có sẵn file .tflite không? | **Không** – chỉ có firmware C++; cần tải .tflite từ Edge Impulse. |
| Input model là gì? | **6435 INT8** (spectrogram), không phải raw PCM. Audio gốc: 1s, 16kHz. |

Nếu bạn có sẵn file `.tflite` (từ Edge Impulse hoặc nguồn khác), bước tiếp theo là thêm pipeline **PCM 1s → spectrogram → INT8** trong app và nối vào `CryClassifier` (hoặc tạo classifier riêng cho model Edge Impulse này).
