import 'package:flutter/material.dart';

import '../theme/peekie_icon_assets.dart';

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

/// Play / pause với cross-fade mượt (mini player, màn hình ru nhạc).
class PeekieAnimatedPlayPauseIcon extends StatelessWidget {
  final bool isPlaying;
  final double size;
  final Duration duration;

  const PeekieAnimatedPlayPauseIcon({
    super.key,
    required this.isPlaying,
    this.size = 40,
    this.duration = const Duration(milliseconds: 280),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedCrossFade(
        duration: duration,
        firstCurve: Curves.easeOutCubic,
        secondCurve: Curves.easeOutCubic,
        sizeCurve: Curves.easeInOutCubic,
        alignment: Alignment.center,
        firstChild: PeekieAssetIcon(
          PeekieMusicNenIcons.playButton,
          size: size,
        ),
        secondChild: PeekieAssetIcon(
          PeekieMusicNenIcons.pause,
          size: size,
        ),
        crossFadeState: isPlaying
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
      ),
    );
  }
}
