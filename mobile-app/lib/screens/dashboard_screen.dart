import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../theme/app_theme.dart';
import '../providers/baby_status_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/camera_settings_provider.dart';
import '../services/noise_detector_service.dart';
import '../services/cry_detector_service.dart';
import '../widgets/pulsating_alert_banner.dart';
import '../widgets/sound_level_meter.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late NoiseDetectorService _noiseDetector;
  late CryDetectorService _cryDetector;
  VlcPlayerController? _videoPlayerController;
  String? _errorMessage;
  bool _isConnecting = true;
  bool _isMuted = false;
  static const int _fullVolume = 100;
  bool _isCryAlertVisible = false;
  DateTime? _cryAlertCooldownUntil;

  @override
  void initState() {
    super.initState();
    final babyStatusProvider = Provider.of<BabyStatusProvider>(context, listen: false);
    _noiseDetector = NoiseDetectorService(babyStatusProvider);
    _cryDetector = CryDetectorService(babyStatusProvider, onCryDetected: _showCryAlert);
    // Chỉ bật phát hiện tiếng khóc khi stream RTSP đã kết nối (trong addOnInitListener)

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CameraSettingsProvider>().load();
      if (!mounted) return;
      setState(() {});
      _initializeVideoPlayer();
    });
  }

  void _initializeVideoPlayer() {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    final settingsProvider = Provider.of<CameraSettingsProvider>(context, listen: false);
    final String? rtspUrl = settingsProvider.rtspUrl;

    if (rtspUrl == null || rtspUrl.isEmpty) {
      _noiseDetector.stopMonitoring();
      _cryDetector.stopMonitoring();
      context.read<BabyStatusProvider>().reset();
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Chưa cấu hình camera. Vào Cài đặt để nhập IP, tên đăng nhập và mật khẩu.';
      });
      cameraProvider.setStreamingStatus(false);
      return;
    }

    _noiseDetector.stopMonitoring();
    _cryDetector.stopMonitoring();
    context.read<BabyStatusProvider>().reset();
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Initializing RTSP stream: $rtspUrl');

      _videoPlayerController = VlcPlayerController.network(
        rtspUrl,
        hwAcc: HwAcc.full,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(1000),
          ]),
          http: VlcHttpOptions([
            VlcHttpOptions.httpReconnect(true),
          ]),
          rtp: VlcRtpOptions([
            VlcRtpOptions.rtpOverRtsp(true),
          ]),
          extras: [
            '--rtsp-tcp',
            '--live-caching=300',
            '--network-caching=1000',
            '--rtsp-frame-buffer-size=500000',
            '--rtsp-caching=300',
          ],
        ),
      );
      
      _videoPlayerController?.addOnInitListener(() {
        debugPrint('VLC Player initialized successfully');
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _errorMessage = null;
          });
          cameraProvider.setStreamingStatus(true);
          _noiseDetector.startMonitoring();
          _cryDetector.startMonitoring();
        }
      });
      
      // Set a timeout to check connection status
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isConnecting) {
          debugPrint('RTSP connection timeout');
          _noiseDetector.stopMonitoring();
          _cryDetector.stopMonitoring();
          context.read<BabyStatusProvider>().reset();
          setState(() {
            _isConnecting = false;
            _errorMessage = 'Kết nối timeout. Vui lòng kiểm tra:\n- Camera đã bật RTSP\n- Cùng mạng WiFi\n- Firewall không chặn port 554';
          });
          cameraProvider.setStreamingStatus(false);
        }
      });
      
    } catch (e, stackTrace) {
      debugPrint('Error initializing VLC Player: $e');
      debugPrint('Stack trace: $stackTrace');
      _noiseDetector.stopMonitoring();
      _cryDetector.stopMonitoring();
      context.read<BabyStatusProvider>().reset();
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Lỗi khởi tạo player: $e';
        });
        cameraProvider.setStreamingStatus(false);
      }
    }
  }

  Future<void> _toggleMute() async {
    if (_videoPlayerController == null) return;
    setState(() => _isMuted = !_isMuted);
    await _videoPlayerController!.setVolume(_isMuted ? 0 : _fullVolume);
  }
  
  void _retryConnection() {
    _videoPlayerController?.stop();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _initializeVideoPlayer();
  }

  void _showCryAlert() {
    if (!mounted) return;
    if (_isCryAlertVisible) return;
    if (_cryAlertCooldownUntil != null && DateTime.now().isBefore(_cryAlertCooldownUntil!)) return;

    _isCryAlertVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Phát hiện tiếng khóc',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        content: const Text(
          'Hệ thống phát hiện tiếng khóc. Bé có thể cần sự chú ý của bạn.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) setState(() => _isCryAlertVisible = false);
            },
            child: const Text('Đã biết'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                setState(() {
                  _isCryAlertVisible = false;
                  _cryAlertCooldownUntil = DateTime.now().add(const Duration(seconds: 5));
                });
              }
            },
            child: const Text('Thông báo lại sau 5s'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) setState(() => _isCryAlertVisible = false);
    });
  }

  @override
  void dispose() {
    _noiseDetector.dispose();
    _cryDetector.dispose();
    _videoPlayerController?.stop();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final babyStatus = Provider.of<BabyStatusProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final streamHeight = (screenWidth * 9) / 16; // 16:9 aspect ratio

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                    child: const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  // Live Stream Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.streamRadius),
                          child: Container(
                            width: screenWidth - 40,
                            height: streamHeight,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              boxShadow: AppTheme.innerGlow,
                            ),
                            child: Stack(
                              children: [
                                // RTSP Video Stream
                                if (_videoPlayerController != null && _errorMessage == null)
                                  VlcPlayer(
                                    controller: _videoPlayerController!,
                                    aspectRatio: 16 / 9,
                                    placeholder: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            _isConnecting 
                                                ? 'Đang kết nối camera...' 
                                                : 'Đang tải video...',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.videocam_off,
                                          size: 60,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _errorMessage ?? 'Không thể kết nối camera',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (_errorMessage != null) ...[
                                          const SizedBox(height: 20),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 8,
                                            alignment: WrapAlignment.center,
                                            children: [
                                              if (_errorMessage?.contains('Chưa cấu hình') == true)
                                                ElevatedButton.icon(
                                                  onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
                                                  icon: const Icon(Icons.settings),
                                                  label: const Text('Vào Cài đặt'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.primaryBlue,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ElevatedButton.icon(
                                                onPressed: _retryConnection,
                                                icon: const Icon(Icons.refresh),
                                                label: const Text('Thử lại'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.primaryBlue,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                // Nút bật/tắt âm thanh (loa)
                                if (_videoPlayerController != null && _errorMessage == null && !_isConnecting)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Material(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(24),
                                      child: InkWell(
                                        onTap: _toggleMute,
                                        borderRadius: BorderRadius.circular(24),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Icon(
                                            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Alert Banner (floating inside video area at bottom-left)
                                if (babyStatus.isCrying)
                                  Positioned(
                                    bottom: 20,
                                    left: 20,
                                    child: const PulsatingAlertBanner(
                                      message: 'Bé đang khóc!',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sound Level Meter
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Center(
                        child: SoundLevelMeter(soundLevel: babyStatus.soundLevel),
                      ),
                    ),
                  ),
                ],
              ),
              // Floating bottom navigation bar
              const CustomBottomNavBar(currentRoute: '/'),
            ],
          ),
        ),
      ),
    );
  }
}

