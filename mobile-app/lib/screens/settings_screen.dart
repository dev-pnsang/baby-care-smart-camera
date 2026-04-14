import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../models/camera_settings.dart';
import '../providers/camera_settings_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ipController;
  late TextEditingController _userController;
  late TextEditingController _passwordController;
  late TextEditingController _pathController;
  bool _obscurePassword = true;
  bool _saving = false;

  /// % tối thiểu để báo khóc (AI). Mặc định 60.
  double _cryDetectMinPercent = 60;

  /// % tối đa: nếu xác suất khóc &lt; mức này → báo noise ngay. Mặc định 50. Phải &lt; [_cryDetectMinPercent].
  double _noiseDetectMaxPercent = 50;

  /// Giây giữa mỗi lần lấy mẫu âm thanh RTSP (mặc định 5).
  double _soundCheckIntervalSeconds = 5;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _userController = TextEditingController();
    _passwordController = TextEditingController();
    _pathController = TextEditingController(text: '/live/ch00_0');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialValues());
  }

  @override
  void dispose() {
    _ipController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialValues() async {
    final p = context.read<CameraSettingsProvider>();
    await p.load(force: true);
    final s = p.settings;
    if (!mounted) return;
    if (s != null) {
      _ipController.text = s.ip;
      _userController.text = s.username;
      _passwordController.text = s.password;
      _pathController.text = s.path;
      _cryDetectMinPercent = s.cryDetectMinPercent.toDouble();
      _noiseDetectMaxPercent = s.noiseDetectMaxPercent.toDouble();
      _soundCheckIntervalSeconds = s.soundCheckIntervalSeconds.toDouble();
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cry = _cryDetectMinPercent.round().clamp(51, 95);
    var noise = _noiseDetectMaxPercent.round().clamp(20, 94);
    if (noise >= cry) {
      noise = cry - 1;
    }
    final intervalSec =
        _soundCheckIntervalSeconds.round().clamp(3, 60);
    setState(() {
      _cryDetectMinPercent = cry.toDouble();
      _noiseDetectMaxPercent = noise.toDouble();
      _soundCheckIntervalSeconds = intervalSec.toDouble();
      _saving = true;
    });
    try {
      final settings = CameraSettings(
        ip: _ipController.text.trim(),
        username: _userController.text.trim(),
        password: _passwordController.text,
        path: _pathController.text.trim().isEmpty
            ? '/live/ch00_0'
            : _pathController.text.trim(),
        cryDetectMinPercent: cry,
        noiseDetectMaxPercent: noise,
        soundCheckIntervalSeconds: intervalSec,
      );
      await context.read<CameraSettingsProvider>().save(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu cấu hình camera'),
            backgroundColor: DesignTokens.success6,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 10),
                      child: Text(
                        'Cài đặt Camera',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _ipController,
                              decoration: InputDecoration(
                                labelText: 'IP Camera',
                                hintText: '192.168.1.80',
                                prefixIcon: const Icon(Icons.wifi),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng nhập IP camera';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _userController,
                              decoration: InputDecoration(
                                labelText: 'Tên đăng nhập',
                                hintText: 'admin',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Vui lòng nhập tên đăng nhập';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pathController,
                              decoration: InputDecoration(
                                labelText: 'Đường dẫn RTSP (tùy chọn)',
                                hintText: '/live/ch00_0',
                                prefixIcon: const Icon(Icons.link),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Nhận diện tiếng khóc (RTSP)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Áp dụng cho audio tách từ luồng camera. Ngưỡng khóc phải lớn hơn ngưỡng noise. Chu kỳ ngắn = phản ứng nhanh nhưng tốn CPU hơn; chu kỳ dài = nhẹ máy nhưng cảnh báo chậm hơn — không làm model “chuẩn hơn” theo nghĩa thống kê.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DesignTokens.neutral12.withOpacity(0.65),
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: DesignTokens.neutral12.withOpacity(0.12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Báo khóc từ'),
                                      Text(
                                        '${_cryDetectMinPercent.round()}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: _cryDetectMinPercent.clamp(51, 95),
                                    min: 51,
                                    max: 95,
                                    divisions: 44,
                                    label: '${_cryDetectMinPercent.round()}%',
                                    onChanged: (v) {
                                      setState(() {
                                        _cryDetectMinPercent = v;
                                        if (_noiseDetectMaxPercent >= v) {
                                          _noiseDetectMaxPercent = v - 1;
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Báo noise nếu dưới'),
                                      Text(
                                        '${_noiseDetectMaxPercent.round()}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: _noiseDetectMaxPercent.clamp(
                                      20,
                                      _cryDetectMinPercent - 1,
                                    ),
                                    min: 20,
                                    max: _cryDetectMinPercent - 1,
                                    divisions: (_cryDetectMinPercent - 1 - 20)
                                        .clamp(1, 74)
                                        .toInt(),
                                    label:
                                        '${_noiseDetectMaxPercent.round()}%',
                                    onChanged: (v) {
                                      setState(() {
                                        _noiseDetectMaxPercent = v;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Kiểm tra âm thanh mỗi'),
                                      Text(
                                        '${_soundCheckIntervalSeconds.round()} giây',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: _soundCheckIntervalSeconds.clamp(
                                        3, 60),
                                    min: 3,
                                    max: 60,
                                    divisions: 57,
                                    label:
                                        '${_soundCheckIntervalSeconds.round()}s',
                                    onChanged: (v) {
                                      setState(() {
                                        _soundCheckIntervalSeconds = v;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.neutral12,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Lưu cấu hình'),
                            ),
                            SizedBox(
                                height: kPeekieShowBottomNavBar ? 120 : 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const CustomBottomNavBar(currentRoute: '/settings'),
            ],
          ),
        ),
      ),
    );
  }
}
