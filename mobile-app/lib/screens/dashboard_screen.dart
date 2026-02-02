import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/baby_status_provider.dart';
import '../services/noise_detector_service.dart';
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

  @override
  void initState() {
    super.initState();
    final babyStatusProvider = Provider.of<BabyStatusProvider>(
      context,
      listen: false,
    );
    _noiseDetector = NoiseDetectorService(babyStatusProvider);
    _noiseDetector.startMonitoring();
  }

  @override
  void dispose() {
    _noiseDetector.dispose();
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
                                // Simulated video feed (placeholder)
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.videocam,
                                        size: 60,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Live Stream',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
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

