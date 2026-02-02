import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/expression_type.dart';
import '../providers/camera_provider.dart';
import '../widgets/neumorphic_button.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class ExpressionControllerScreen extends StatefulWidget {
  const ExpressionControllerScreen({super.key});

  @override
  State<ExpressionControllerScreen> createState() =>
      _ExpressionControllerScreenState();
}

class _ExpressionControllerScreenState
    extends State<ExpressionControllerScreen> {
  ExpressionType? _selectedExpression;

  Future<void> _handleExpressionTap(ExpressionType type) async {
    setState(() {
      _selectedExpression = type;
    });

    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    await cameraProvider.updateExpression(type);

    if (mounted) {
      _showSuccessBottomSheet();
    }
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.borderRadius),
          ),
          boxShadow: AppTheme.neumorphicShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.primaryBlue,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cập nhật biểu cảm thành công',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            NeumorphicButton(
              width: double.infinity,
              height: 50,
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              // Main content
              Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Stack(
                      children: [
                        Center(
                          child: const Text(
                            'Điều khiển Biểu Cảm',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: NeumorphicButton(
                            width: 50,
                            height: 50,
                            onPressed: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppTheme.textDark,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Emoji Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: 20.0,
                        bottom: 100.0,
                      ),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1,
                        ),
                        itemCount: ExpressionType.values.length,
                        itemBuilder: (context, index) {
                          final expression = ExpressionType.values[index];
                          final isSelected = _selectedExpression == expression;

                          return NeumorphicButton(
                            isActive: isSelected,
                            activeGlowColor: AppTheme.primaryBlue,
                            onPressed: () => _handleExpressionTap(expression),
                            child: Text(
                              expression.emoji,
                              style: const TextStyle(fontSize: 50),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Action Button
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      bottom: 100.0,
                    ),
                    child: NeumorphicButton(
                      width: double.infinity,
                      height: 60,
                      onPressed: () {
                        if (_selectedExpression != null) {
                          _handleExpressionTap(_selectedExpression!);
                        }
                      },
                      child: const Text(
                        'Phát tiếng cười & mặt vui vẻ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Floating bottom navigation bar
              const CustomBottomNavBar(currentRoute: '/expression'),
            ],
          ),
        ),
      ),
    );
  }
}

