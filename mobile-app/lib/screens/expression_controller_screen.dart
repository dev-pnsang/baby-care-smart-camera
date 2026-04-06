import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/design_tokens.dart';
import '../models/expression_type.dart';
import '../providers/camera_provider.dart';
import '../widgets/expression_bubble_widget.dart';
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
    
    // Notify hardware with expression ID and trigger sound effect
    await cameraProvider.notifyHardware(type.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: DesignTokens.sunlight2,
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
                          child: Text(
                            'Tuỳ chỉnh nâng cao',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expression Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 25,
                        crossAxisSpacing: 25,
                        childAspectRatio: 0.85,
                        children: ExpressionType.values.map((expression) {
                          final isSelected = _selectedExpression == expression;
                          return ExpressionBubbleWidget(
                            expression: expression,
                            isSelected: isSelected,
                            onTap: () => _handleExpressionTap(expression),
                          );
                        }).toList(),
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
