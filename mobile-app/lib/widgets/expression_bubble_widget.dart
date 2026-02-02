import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expression_type.dart';
import '../theme/app_theme.dart';

class ExpressionBubbleWidget extends StatefulWidget {
  final ExpressionType expression;
  final bool isSelected;
  final VoidCallback onTap;

  const ExpressionBubbleWidget({
    super.key,
    required this.expression,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ExpressionBubbleWidget> createState() => _ExpressionBubbleWidgetState();
}

class _ExpressionBubbleWidgetState extends State<ExpressionBubbleWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Bubble Container
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 120,
            height: 120,
            transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF0F7FF)],
              ),
              border: widget.isSelected
                  ? Border.all(
                      color: const Color(0xFFA2D2FF),
                      width: 3,
                    )
                  : null,
              boxShadow: [
                // Dark shadow at bottom-right
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(8, 8),
                ),
                // White highlight at top-left
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 15,
                  offset: const Offset(-8, -8),
                ),
                // Inner glow when selected
                if (widget.isSelected)
                  BoxShadow(
                    color: const Color(0xFFA2D2FF).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
              ],
            ),
            child: Container(
              decoration: widget.isSelected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.7,
                        colors: [
                          const Color(0xFFA2D2FF).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    )
                  : null,
              child: Center(
                child: Text(
                  widget.expression.emoji,
                  style: const TextStyle(fontSize: 60),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Label Text
          Text(
            widget.expression.name,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.isSelected
                  ? AppTheme.primaryBlue
                  : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

