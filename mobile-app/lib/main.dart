import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/baby_status_provider.dart';
import 'providers/camera_provider.dart';
import 'providers/camera_settings_provider.dart';
import 'providers/music_player_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expression_controller_screen.dart';
import 'screens/lullaby_player_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  // Broker uses self-signed certificate (wss). Allow it for this host only.
  // NOTE: This is a security trade-off; ideally install a valid cert or pin.
  HttpOverrides.global = _MqttHttpOverrides(allowedHost: 'mqtt.goads.com.vn');
  runApp(const BabyCareSmartCamApp());
}

class BabyCareSmartCamApp extends StatelessWidget {
  const BabyCareSmartCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BabyStatusProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => CameraSettingsProvider()),
        ChangeNotifierProvider(create: (_) => MusicPlayerProvider()),
      ],
      child: MaterialApp(
        title: 'BabyCare SmartCam',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const DashboardScreen(),
          '/expression': (context) => const ExpressionControllerScreen(),
          '/lullaby': (context) => const LullabyPlayerScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

class _MqttHttpOverrides extends HttpOverrides {
  final String allowedHost;
  _MqttHttpOverrides({required this.allowedHost});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) =>
            host == allowedHost || host.endsWith('.goads.com.vn');
    return client;
  }
}

