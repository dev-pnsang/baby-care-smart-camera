import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/baby_status_provider.dart';
import 'providers/camera_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expression_controller_screen.dart';
import 'screens/lullaby_player_screen.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: 'BabyCare SmartCam',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primaryBlue,
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const DashboardScreen(),
          '/expression': (context) => const ExpressionControllerScreen(),
          '/lullaby': (context) => const LullabyPlayerScreen(),
        },
      ),
    );
  }
}

