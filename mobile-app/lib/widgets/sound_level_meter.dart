import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';

class SoundLevelMeter extends StatelessWidget {
  final double soundLevel; // dB value

  const SoundLevelMeter({
    super.key,
    required this.soundLevel,
  });

  @override
  Widget build(BuildContext context) {
    // Normalize dB to percentage (assuming 0-100 dB range)
    double percentage = (soundLevel / 100).clamp(0.0, 1.0);
    
    // Determine color based on level
    Color indicatorColor = soundLevel > 70
        ? AppTheme.alertRed
        : soundLevel > 50
            ? Colors.orange
            : AppTheme.primaryBlue;

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        shape: BoxShape.circle,
        boxShadow: AppTheme.neumorphicShadow,
      ),
      child: CircularPercentIndicator(
        radius: 90,
        lineWidth: 12,
        percent: percentage,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sound Level:',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${soundLevel.toInt()} dB',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              Icons.mic,
              size: 32,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: indicatorColor,
        backgroundColor: Colors.grey.shade200,
        animation: true,
        animationDuration: 300,
      ),
    );
  }
}

