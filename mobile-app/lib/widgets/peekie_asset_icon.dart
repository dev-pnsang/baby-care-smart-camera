import 'package:flutter/material.dart';

/// Renders a PNG from [PeekieIconAssets]. Optional [color] tints via [BlendMode.srcIn]
/// (works best for single-color / template icons).
class PeekieAssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;
  final BoxFit fit;

  const PeekieAssetIcon(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined,
          size: size * 0.85, color: color ?? Theme.of(context).disabledColor),
    );
    if (color != null) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: child,
      );
    }
    return child;
  }
}
