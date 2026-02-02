import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final bool isActive;
  final Color? activeGlowColor;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.isActive = false,
    this.activeGlowColor,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: widget.isActive
              ? [
                  ...AppTheme.neumorphicShadow,
                  BoxShadow(
                    color: (widget.activeGlowColor ?? AppTheme.primaryBlue)
                        .withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : _isPressed
                  ? [
                      BoxShadow(
                        color: const Color(0xFFB0C4DE).withOpacity(0.3),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ]
                  : AppTheme.neumorphicShadow,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

