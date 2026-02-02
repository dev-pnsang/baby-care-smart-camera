import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int? currentIndex;
  final Function(int)? onTap;
  final String? currentRoute;

  const CustomBottomNavBar({
    super.key,
    this.currentIndex,
    this.onTap,
    this.currentRoute,
  });

  int _getCurrentIndex() {
    if (currentIndex != null) return currentIndex!;
    if (currentRoute != null) {
      switch (currentRoute) {
        case '/':
          return 0;
        case '/expression':
          return 1;
        case '/lullaby':
          return 2;
        default:
          return 0;
      }
    }
    return 0;
  }

  void _handleTap(int index, BuildContext context) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    // Default route-based navigation
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/expression');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/lullaby');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = 20.0;
    final barWidth = screenWidth - (horizontalMargin * 2);
    final barHeight = 75.0;
    final activeIndex = _getCurrentIndex();

    return Positioned(
      bottom: 20,
      left: horizontalMargin,
      right: horizontalMargin,
      child: Container(
        width: barWidth,
        height: barHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Dashboard',
                    isActive: activeIndex == 0,
                    onTap: () => _handleTap(0, context),
                  ),
                  _NavItem(
                    icon: Icons.face_retouching_natural_rounded,
                    label: 'Expression',
                    isActive: activeIndex == 1,
                    onTap: () => _handleTap(1, context),
                  ),
                  _NavItem(
                    icon: Icons.music_note_rounded,
                    label: 'Music',
                    isActive: activeIndex == 2,
                    onTap: () => _handleTap(2, context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  @override
  Widget build(BuildContext context) {
    // Active color: Soft Blue #A2D2FF
    const activeColor = Color(0xFFA2D2FF);
    // Inactive color: Muted Grey #B2BEC3
    const inactiveColor = Color(0xFFB2BEC3);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isActive
              ? activeColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    widget.icon,
                    color: widget.isActive ? activeColor : inactiveColor,
                    size: 28,
                  ),
                ),
                // Glowing dot indicator for active state
                if (widget.isActive)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: AnimatedOpacity(
                      opacity: widget.isActive ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withOpacity(0.8),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: 12,
                color: widget.isActive ? activeColor : inactiveColor,
                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}

