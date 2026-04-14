import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../providers/baby_status_provider.dart';
import '../providers/camera_provider.dart';
import '../models/camera_settings.dart';
import '../providers/camera_settings_provider.dart';
import '../services/noise_detector_service.dart';
import '../theme/peekie_icon_assets.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/peekie_asset_icon.dart';
import '../widgets/peekie_expression_customize_sheet.dart';
import '../widgets/peekie_home_widgets.dart';
import '../widgets/lullaby_library_sheet.dart';
import '../services/mqtt_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late NoiseDetectorService _noiseDetector;
  late BabyStatusProvider _babyStatusProvider;
  late CameraSettingsProvider _cameraSettingsProvider;
  VlcPlayerController? _videoPlayerController;
  String? _errorMessage;
  bool _isConnecting = true;
  bool _isMuted = false;
  static const int _fullVolume = 100;
  bool _muteBusy = false;
  bool _isFullscreen = false;

  bool _soothingMode = false;
  bool _expressionScreenOn = true;
  PeekieQuickExpression _quickExpression = PeekieQuickExpression.auto;
  String _customEmotionChannelId = 'vui_mung';

  bool _cryDialogOffered = false;
  bool _noiseDialogOffered = false;
  double _lastSoundLevel = 0;
  bool _soundLevelPrimed = false;
  late final VoidCallback _babyStatusListener;

  @override
  void initState() {
    super.initState();
    _babyStatusProvider =
        Provider.of<BabyStatusProvider>(context, listen: false);
    _cameraSettingsProvider =
        Provider.of<CameraSettingsProvider>(context, listen: false);
    _cameraSettingsProvider.addListener(_onCameraCrySettingsChanged);
    _noiseDetector = NoiseDetectorService(_babyStatusProvider);

    _babyStatusListener = _onBabyStatusChanged;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _babyStatusProvider.addListener(_babyStatusListener);
      await context.read<CameraSettingsProvider>().load();
      if (!mounted) return;
      setState(() {});
      _initializeVideoPlayer();
    });
  }

  void _applyCryThresholdsFromSettings(CameraSettings? s) {
    final cry = ((s?.cryDetectMinPercent ?? 60).clamp(51, 95)) / 100.0;
    var noise = ((s?.noiseDetectMaxPercent ?? 50).clamp(20, 94)) / 100.0;
    if (noise >= cry) {
      noise = cry - 0.01;
    }
    _noiseDetector.updateCryThresholds(
      cryProbThreshold: cry,
      noiseProbThreshold: noise,
    );
  }

  void _onCameraCrySettingsChanged() {
    if (!mounted) return;
    final s = _cameraSettingsProvider.settings;
    _applyCryThresholdsFromSettings(s);
    final interval = (s?.soundCheckIntervalSeconds ?? 5).clamp(3, 60);
    _noiseDetector.updateSampleInterval(interval);
  }

  void _onBabyStatusChanged() {
    if (!mounted) return;
    final baby = _babyStatusProvider;
    final soundState = baby.crySoundState;
    final crying = soundState == CrySoundState.crying;
    final level = baby.soundLevel;

    if (!_soundLevelPrimed) {
      _soundLevelPrimed = true;
      _lastSoundLevel = level;
    }

    if (!crying) {
      _cryDialogOffered = false;
    }

    if (crying && !_cryDialogOffered) {
      _cryDialogOffered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_babyStatusProvider.crySoundState != CrySoundState.crying) return;
        showPeekieCryDialog(
          context,
          babyName: 'Bi',
          onSoothing: () {
            setState(() => _soothingMode = true);
            _openLullabySheet();
          },
          onDismiss: () {},
        );
      });
    }

    if (_soundLevelPrimed &&
        soundState == CrySoundState.noise &&
        level >= 60 &&
        _lastSoundLevel < 60 &&
        !_noiseDialogOffered) {
      _noiseDialogOffered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showPeekieNoiseDialog(context, onAck: () {});
      });
    }
    if (level < 48) _noiseDialogOffered = false;
    _lastSoundLevel = level;
  }

  void _initializeVideoPlayer() {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    final settingsProvider =
        Provider.of<CameraSettingsProvider>(context, listen: false);
    final String? rtspUrl = settingsProvider.rtspUrl;

    if (rtspUrl == null || rtspUrl.isEmpty) {
      _noiseDetector.stopMonitoring();
      context.read<BabyStatusProvider>().reset();
      setState(() {
        _isConnecting = false;
        _errorMessage =
            'Chưa cấu hình camera. Vào Cài đặt để nhập IP, tên đăng nhập và mật khẩu.';
      });
      cameraProvider.setStreamingStatus(false);
      return;
    }

    _noiseDetector.stopMonitoring();
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
          final s = settingsProvider.settings;
          final cry = ((s?.cryDetectMinPercent ?? 60).clamp(51, 95)) / 100.0;
          var noise = ((s?.noiseDetectMaxPercent ?? 50).clamp(20, 94)) / 100.0;
          if (noise >= cry) {
            noise = cry - 0.01;
          }
          final interval = (s?.soundCheckIntervalSeconds ?? 5).clamp(3, 60);
          _noiseDetector.startMonitoring(
            rtspUrl,
            sampleIntervalSeconds: interval,
            cryProbThreshold: cry,
            noiseProbThreshold: noise,
          );
        }
      });

      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isConnecting) {
          debugPrint('RTSP connection timeout');
          _noiseDetector.stopMonitoring();
          context.read<BabyStatusProvider>().reset();
          setState(() {
            _isConnecting = false;
            _errorMessage =
                'Kết nối timeout. Vui lòng kiểm tra:\n- Camera đã bật RTSP\n- Cùng mạng WiFi\n- Firewall không chặn port 554';
          });
          cameraProvider.setStreamingStatus(false);
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error initializing VLC Player: $e');
      debugPrint('Stack trace: $stackTrace');
      _noiseDetector.stopMonitoring();
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
    final controller = _videoPlayerController;
    if (controller == null) return;
    if (_muteBusy) return;
    _muteBusy = true;
    final nextMuted = !_isMuted;
    try {
      await controller.setVolume(nextMuted ? 0 : _fullVolume);
      if (!mounted) return;
      setState(() => _isMuted = nextMuted);
    } finally {
      _muteBusy = false;
    }
  }

  void _retryConnection() {
    _videoPlayerController?.stop();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _initializeVideoPlayer();
  }

  void _openFullscreen() {
    if (_videoPlayerController == null || _errorMessage != null) return;
    setState(() => _isFullscreen = true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _closeFullscreen() {
    if (!_isFullscreen) return;
    setState(() => _isFullscreen = false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _cameraSettingsProvider.removeListener(_onCameraCrySettingsChanged);
    _babyStatusProvider.removeListener(_babyStatusListener);
    _noiseDetector.dispose();
    _videoPlayerController?.stop();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _openLullabySheet() async {
    if (!mounted) return;
    await showLullabyLibrarySheet(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen && _videoPlayerController != null && _errorMessage == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final screenAspect = (h == 0) ? (16 / 9) : (w / h);
                return Center(
                  child: VlcPlayer(
                    controller: _videoPlayerController!,
                    aspectRatio: screenAspect,
                  ),
                );
              },
            ),
            const StreamHudOverlay(),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: _closeFullscreen,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final streamHeight = screenWidth * 9 / 16;

    return Scaffold(
      backgroundColor: DesignTokens.neutral1, // #FDFDFD
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PeekieTopBar(
                    onSettings: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.streamRadius),
                    child: Container(
                      width: screenWidth,
                      height: streamHeight,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        boxShadow: AppTheme.innerGlow,
                      ),
                      child: Stack(
                        children: [
                                  if (_videoPlayerController != null &&
                                      _errorMessage == null)
                                    VlcPlayer(
                                      controller: _videoPlayerController!,
                                      aspectRatio: 16 / 9,
                                      placeholder: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final compact =
                                            constraints.maxHeight < 180;
                                        final iconSize = compact ? 44.0 : 60.0;
                                        final gap1 = compact ? 8.0 : 10.0;
                                        final gap2 = compact ? 12.0 : 20.0;
                                        final fontSize = compact ? 13.0 : 16.0;

                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: SingleChildScrollView(
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.videocam_off,
                                                    size: iconSize,
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                  ),
                                                  SizedBox(height: gap1),
                                                  Text(
                                                    _errorMessage ??
                                                        'Không thể kết nối camera',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                      fontSize: fontSize,
                                                    ),
                                                    maxLines: compact ? 3 : 6,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  if (_errorMessage != null) ...[
                                                    SizedBox(height: gap2),
                                                    Wrap(
                                                      spacing: 12,
                                                      runSpacing: 8,
                                                      alignment:
                                                          WrapAlignment.center,
                                                      children: [
                                                        if (_errorMessage
                                                                ?.contains(
                                                                    'Chưa cấu hình') ==
                                                            true)
                                                          FilledButton.icon(
                                                            onPressed: () =>
                                                                Navigator
                                                                    .pushReplacementNamed(
                                                                        context,
                                                                        '/settings'),
                                                            icon: const Icon(
                                                                Icons.settings),
                                                            label: const Text(
                                                                'Vào Cài đặt'),
                                                          ),
                                                        FilledButton.icon(
                                                          onPressed:
                                                              _retryConnection,
                                                          icon: const Icon(
                                                              Icons.refresh),
                                                          label: const Text(
                                                              'Thử lại'),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  if (_videoPlayerController != null &&
                                      _errorMessage == null)
                                    const StreamHudOverlay(),
                          if (_videoPlayerController != null &&
                              _errorMessage == null &&
                              !_isConnecting)
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: Material(
                                        color: Colors.white.withOpacity(0.92),
                                        elevation: 2,
                                        shadowColor:
                                            Colors.black.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        child: InkWell(
                                          onTap: _openFullscreen,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.open_in_full_rounded,
                                              color: DesignTokens.neutral12,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_videoPlayerController != null &&
                            _errorMessage == null)
                          NavyCameraToolbar(
                            isMuted: _isMuted,
                            onToggleMute: _toggleMute,
                            onFullscreen: _openFullscreen,
                          ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EnvStatCard(
                              leading: PeekieAssetIcon(
                                PeekieIconAssets.temperature,
                                size: 24,
                                color: DesignTokens.neutral12,
                              ),
                              label: 'Nhiệt độ',
                              value: '26°C',
                              footer: 'Nhiệt độ TB: 27°C',
                              statusLabel: 'Ổn',
                              statusBg: const Color(0xFF25A249),
                              statusFg: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            EnvStatCard(
                              leading: PeekieAssetIcon(
                                PeekieIconAssets.humidity,
                                size: 24,
                                color: DesignTokens.neutral12,
                              ),
                              label: 'Độ ẩm',
                              value: '40%',
                              footer: 'Độ ẩm TB: 40%',
                              statusLabel: 'Hơi khô',
                              statusBg: const Color(0xFFF1A61B),
                              statusFg: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        MiniMusicCard(
                          onOpenLibrary: _openLullabySheet,
                        ),
                        const SizedBox(height: 14),
                        ExpressionPeekieCard(
                          enabled: _expressionScreenOn,
                          onEnabledChanged: (v) =>
                              setState(() => _expressionScreenOn = v),
                          selectedQuick: _quickExpression,
                          onPickAuto: () {
                            setState(() =>
                                _quickExpression = PeekieQuickExpression.auto);
                            notifyExpressionIfEnabled(context, 'calm');
                          },
                          onPickHappy: () {
                            setState(() =>
                                _quickExpression = PeekieQuickExpression.happy);
                            notifyExpressionIfEnabled(context, 'happy');
                          },
                          onPickRelax: () {
                            setState(() =>
                                _quickExpression = PeekieQuickExpression.relax);
                            notifyExpressionIfEnabled(context, 'calm');
                          },
                          onCustomize: () {
                            // Start MQTT connection early so emotion taps can publish immediately.
                            unawaited(MqttService.instance.ensureConnected());
                            showPeekieExpressionCustomizeSheet(
                              context,
                              initialChannelId: _customEmotionChannelId,
                              onSelected: (opt) {
                                if (!mounted) return;
                                setState(() {
                                  _quickExpression = PeekieQuickExpression.custom;
                                  _customEmotionChannelId = opt.channelId;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        SoothingModeBar(
                          enabled: _soothingMode,
                          onChanged: (v) => setState(() => _soothingMode = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  showPeekieNoiseDialog(
                                    context,
                                    onAck: () {},
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: DesignTokens.neutral12,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Test thông báo ồn'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  showPeekieCryDialog(
                                    context,
                                    babyName: 'Bi',
                                    onSoothing: () {},
                                    onDismiss: () {},
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFCCE6FF),
                                  foregroundColor: DesignTokens.neutral12,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Test thông báo khóc'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: kPeekieShowBottomNavBar ? 120 : 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const CustomBottomNavBar(currentRoute: '/'),
          ],
        ),
      ),
    );
  }
}
