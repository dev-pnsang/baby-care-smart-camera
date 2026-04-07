import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/design_tokens.dart';
import '../theme/peekie_gradients.dart';
import '../theme/peekie_icon_assets.dart';
import '../providers/camera_provider.dart';
import '../services/mqtt_service.dart';
import '../providers/music_player_provider.dart';
import '../models/song.dart';
import 'peekie_asset_icon.dart';

double _peekieCardTitleFontSize(BuildContext context) {
  final s = MediaQuery.sizeOf(context).shortestSide;
  if (s < 360) return 11; // very small phones
  if (s < 400) return 12; // small phones
  if (s < 600) return 14; // regular phones
  return 16; // tablets / large screens
}

double _peekieEnvLeadingSize(BuildContext context) {
  final s = MediaQuery.sizeOf(context).shortestSide;
  if (s < 360) return 16; // very small phones
  if (s < 400) return 18; // small phones
  if (s < 600) return 22; // regular phones
  return 24; // tablets / large screens
}

double _peekieEnvStatusMaxWidth(BuildContext context) {
  final s = MediaQuery.sizeOf(context).shortestSide;
  if (s < 360) return 50;
  if (s < 400) return 58;
  return 66;
}

EdgeInsets _peekieEnvStatusPadding(BuildContext context) {
  final s = MediaQuery.sizeOf(context).shortestSide;
  if (s < 360) return const EdgeInsets.symmetric(horizontal: 6, vertical: 2.0);
  if (s < 400) return const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5);
  return const EdgeInsets.symmetric(horizontal: 8, vertical: 3.0);
}

TextStyle? _peekieCardTitleStyle(BuildContext context) {
  final t = Theme.of(context).textTheme;
  return t.titleLarge?.copyWith(
    fontSize: _peekieCardTitleFontSize(context),
    fontWeight: FontWeight.w800,
    color: DesignTokens.neutral12,
  );
}

double _peekieBadgeFontSize(BuildContext context) {
  final base = _peekieCardTitleFontSize(context) - 4;
  return base.clamp(8, 10).toDouble();
}

TextStyle? _peekieBadgeStyle(BuildContext context, {required Color color}) {
  final t = Theme.of(context).textTheme;
  return t.labelSmall?.copyWith(
    color: color,
    fontWeight: FontWeight.w800,
    fontSize: _peekieBadgeFontSize(context),
  );
}

class PeekieTopBar extends StatelessWidget {
  final String babyName;
  final VoidCallback? onBack;
  final VoidCallback onSettings;
  final VoidCallback? onShare;

  const PeekieTopBar({
    super.key,
    this.babyName = 'Bi',
    this.onBack,
    required this.onSettings,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack ?? () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: DesignTokens.neutral12,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: DesignTokens.neutral12,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  babyName,
                  style: text.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white, size: 22),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onShare ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chia sẻ — sắp có')),
                          );
                        },
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: PeekieAssetIcon(
                      PeekieIconAssets.share01,
                      size: 24,
                      color: DesignTokens.neutral12,
                    ),
                  ),
                  IconButton(
                    onPressed: onSettings,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: PeekieAssetIcon(
                      PeekieIconAssets.settingsToolbar,
                      size: 24,
                      color: DesignTokens.neutral12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreamHudOverlay extends StatefulWidget {
  final bool showLive;

  const StreamHudOverlay({super.key, this.showLive = true});

  @override
  State<StreamHudOverlay> createState() => _StreamHudOverlayState();
}

class _StreamHudOverlayState extends State<StreamHudOverlay> {
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _timeStr() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}:'
        '${n.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.showLive)
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: DesignTokens.error6,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.signal_cellular_alt_rounded,
                          color: Colors.white.withOpacity(0.9), size: 16),
                      const SizedBox(width: 8),
                      Icon(Icons.battery_full_rounded,
                          color: Colors.white.withOpacity(0.9), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '100%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_rounded,
                    color: Colors.amber.shade200, size: 18),
                const SizedBox(width: 8),
                Text(
                  _timeStr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class NavyCameraToolbar extends StatelessWidget {
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback? onFullscreen;

  const NavyCameraToolbar({
    super.key,
    required this.isMuted,
    required this.onToggleMute,
    this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    Widget assetBtn(String asset, VoidCallback? onTap) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: PeekieAssetIcon(asset, size: 24, color: Colors.white),
          ),
        ),
      );
    }

    void stub(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    final volumeAsset =
        isMuted ? PeekieIconAssets.volumeMedium : PeekieIconAssets.volumeHigh;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.neutral12,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          assetBtn(PeekieIconAssets.record, () => stub('Ghi hình — sắp có')),
          assetBtn(PeekieIconAssets.camera, () => stub('Chụp ảnh — sắp có')),
          assetBtn(
              PeekieIconAssets.microphone, () => stub('Đàm thoại — sắp có')),
          assetBtn(volumeAsset, onToggleMute),
          assetBtn(
            PeekieIconAssets.pictureInPicture,
            onFullscreen ?? () => stub('PiP — sắp có'),
          ),
        ],
      ),
    );
  }
}

class EnvStatCard extends StatelessWidget {
  final Widget leading;
  final String label;
  final String value;
  final String footer;
  final String statusLabel;
  final Color statusBg;
  final Color statusFg;

  const EnvStatCard({
    super.key,
    required this.leading,
    required this.label,
    required this.value,
    required this.footer,
    required this.statusLabel,
    required this.statusBg,
    required this.statusFg,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE2F1FF),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neutral12.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _peekieEnvLeadingSize(context),
                  height: _peekieEnvLeadingSize(context),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: leading,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: _peekieCardTitleStyle(context),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _peekieEnvStatusMaxWidth(context),
                  ),
                  child: Container(
                    padding: _peekieEnvStatusPadding(context),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        softWrap: false,
                        style: _peekieBadgeStyle(context, color: statusFg),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: t.headlineLarge?.copyWith(
                color: DesignTokens.neutral12,
                fontWeight: FontWeight.w800,
                fontSize: 40,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              footer,
              style: t.bodySmall?.copyWith(
                color: DesignTokens.neutral9,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniMusicCard extends StatelessWidget {
  final VoidCallback onOpenLibrary;

  const MiniMusicCard({
    super.key,
    required this.onOpenLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final player = context.watch<MusicPlayerProvider>();
    final song = player.currentSong;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenLibrary,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.neutral12.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: PeekieGradients.musicNenHomeCard,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.48,
                    child: Image.asset(
                      PeekieImageAssets.backgroundNhacNen,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PeekieAssetIcon(
                            PeekieIconAssets.musicNote,
                            size: 20,
                            color: DesignTokens.neutral12,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Nhạc nền',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _peekieCardTitleStyle(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: DesignTokens.neutral12
                                          .withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: PeekieAssetIcon(
                                    PeekieIconAssets.playlist,
                                    size: 22,
                                    color: DesignTokens.neutral12,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -1,
                                right: -1,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: DesignTokens.error6,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      DesignTokens.neutral12.withOpacity(0.08),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                song.thumbnailAsset,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: t.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: DesignTokens.neutral12,
                                  ),
                                ),
                                Text(
                                  _categoryLabel(song.category),
                                  style: t.bodySmall?.copyWith(
                                    color: DesignTokens.neutral10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: player.progress,
                          minHeight: 6,
                          backgroundColor: DesignTokens.babyBlue3,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            DesignTokens.neutral12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Keep transport controls visually consistent.
                          const controlSize = 45.0;
                          const gap = 12.0;
                          final w = constraints.maxWidth;
                          final center = w / 2;
                          return SizedBox(
                            height: controlSize,
                            width: double.infinity,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: center -
                                      controlSize / 2 -
                                      gap -
                                      controlSize,
                                  top: 0,
                                  bottom: 0,
                                  width: controlSize,
                                  child: Center(
                                    child: InkWell(
                                      onTap: () => player.previous(),
                                      borderRadius: BorderRadius.circular(999),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: PeekieAssetIcon(
                                          PeekieMusicNenIcons
                                              .playSkipBackCircle,
                                          size: controlSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: center - controlSize / 2,
                                  top: 0,
                                  bottom: 0,
                                  width: controlSize,
                                  child: Center(
                                    child: InkWell(
                                      onTap: () => player.togglePlayPause(),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: player.isPlaying
                                            ? const PeekieAssetIcon(
                                                PeekieMusicNenIcons.pause,
                                                size: controlSize,
                                              )
                                            : Container(
                                                width: controlSize,
                                                height: controlSize,
                                                decoration: const BoxDecoration(
                                                  color: DesignTokens.neutral12,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: Colors.white,
                                                  size: 32,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: center + controlSize / 2 + gap,
                                  top: 0,
                                  bottom: 0,
                                  width: controlSize,
                                  child: Center(
                                    child: InkWell(
                                      onTap: () => player.next(),
                                      borderRadius: BorderRadius.circular(999),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: PeekieAssetIcon(
                                          PeekieMusicNenIcons
                                              .playSkipForwardCircle,
                                          size: controlSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: InkWell(
                                      onTap: () => player.toggleMute(),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          player.isMuted
                                              ? Icons.volume_off_rounded
                                              : Icons.volume_up_rounded,
                                          size: 26,
                                          color: DesignTokens.neutral12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _categoryLabel(SongCategory c) {
  switch (c) {
    case SongCategory.whiteNoise:
      return 'Tiếng ồn trắng';
    case SongCategory.lullaby:
      return 'Hát ru';
    case SongCategory.fairyTale:
      return 'Truyện cổ tích';
  }
}

enum PeekieQuickExpression { auto, happy, relax, custom }

class ExpressionPeekieCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final PeekieQuickExpression selectedQuick;
  final VoidCallback onPickAuto;
  final VoidCallback onPickHappy;
  final VoidCallback onPickRelax;
  final VoidCallback onCustomize;

  static const Color _enabledTrack = Color(0xFF1B2E53);
  static const Color _disabledTrack = Color(0xFFE6E9EF);
  static const Color _thumbColor = Colors.white;

  const ExpressionPeekieCard({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
    this.selectedQuick = PeekieQuickExpression.auto,
    required this.onPickAuto,
    required this.onPickHappy,
    required this.onPickRelax,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D3),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.neutral12.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PeekieAssetIcon(PeekieIconAssets.happy, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Màn hình biểu cảm Peekie',
                  style: _peekieCardTitleStyle(context),
                ),
              ),
              _PeekieToggle(
                value: enabled,
                onChanged: onEnabledChanged,
                enabledTrackColor: _enabledTrack,
                disabledTrackColor: _disabledTrack,
                thumbColor: _thumbColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _exprChip(
                      context, 'Tự động', PeekieIconAssets.autoMode, onPickAuto,
                      selected: selectedQuick == PeekieQuickExpression.auto)),
              const SizedBox(width: 8),
              Expanded(
                  child: _exprChip(context, 'Vui mừng',
                      PeekieIconAssets.happyAlt, onPickHappy,
                      selected: selectedQuick == PeekieQuickExpression.happy)),
              const SizedBox(width: 8),
              Expanded(
                  child: _exprChip(context, 'Thư giãn',
                      PeekieIconAssets.relieved, onPickRelax,
                      selected: selectedQuick == PeekieQuickExpression.relax)),
              const SizedBox(width: 8),
              Expanded(
                  child: _exprChip(context, 'Tuỳ chỉnh',
                      PeekieIconAssets.customize, onCustomize,
                      selected: selectedQuick == PeekieQuickExpression.custom)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exprChip(
    BuildContext context,
    String label,
    String assetPath,
    VoidCallback onTap, {
    bool selected = false,
  }) {
    final bg = selected
        ? DesignTokens.neutral1
        : Colors.transparent;
    const fg = DesignTokens.neutral12;
    final glyph = PeekieAssetIcon(assetPath, size: 26, color: fg);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              glyph,
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeekieToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color enabledTrackColor;
  final Color disabledTrackColor;
  final Color thumbColor;

  const _PeekieToggle({
    required this.value,
    required this.onChanged,
    required this.enabledTrackColor,
    required this.disabledTrackColor,
    required this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    const w = 44.0;
    const h = 24.0;
    const r = 20.0;
    const pad = 2.0;
    final track = value ? enabledTrackColor : disabledTrackColor;
    final shadow = value
        ? enabledTrackColor.withOpacity(0.28)
        : Colors.black.withOpacity(0.10);

    return Semantics(
      button: true,
      toggled: value,
      label: 'Bật tắt màn hình biểu cảm Peekie',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: w,
            height: h,
            padding: const EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(r),
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: h - pad * 2,
                height: h - pad * 2,
                decoration: BoxDecoration(
                  color: thumbColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SoothingModeBar extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  static const Color _enabledTrack = Color(0xFF1B2E53);
  static const Color _disabledTrack = Color(0xFFE6E9EF);
  static const Color _thumbColor = Colors.white;

  const SoothingModeBar({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          PeekieAssetIcon(PeekieIconAssets.cloud, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Chế độ Dỗ dành',
                    style: _peekieCardTitleStyle(context),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.help_outline_rounded,
                    size: 18, color: DesignTokens.neutral10),
              ],
            ),
          ),
          _PeekieToggle(
            value: enabled,
            onChanged: onChanged,
            enabledTrackColor: _enabledTrack,
            disabledTrackColor: _disabledTrack,
            thumbColor: _thumbColor,
          ),
        ],
      ),
    );
  }
}

class CompactSoundMeter extends StatelessWidget {
  final double soundLevel;

  const CompactSoundMeter({super.key, required this.soundLevel});

  @override
  Widget build(BuildContext context) {
    final pct = (soundLevel / 100).clamp(0.0, 1.0);
    final color = soundLevel > 70
        ? DesignTokens.error6
        : soundLevel > 55
            ? DesignTokens.warning6
            : DesignTokens.success6;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.neutral12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.graphic_eq_rounded, color: DesignTokens.neutral11),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mức âm thanh',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.neutral12,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: DesignTokens.neutral5,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${soundLevel.toInt()}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.neutral12,
                ),
          ),
        ],
      ),
    );
  }
}

Future<void> showPeekieCryDialog(
  BuildContext context, {
  required String babyName,
  required VoidCallback onSoothing,
  required VoidCallback onDismiss,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 44, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bé $babyName đang khóc',
                        textAlign: TextAlign.center,
                        style: t.headlineLarge?.copyWith(
                          color: DesignTokens.neutral12,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text.rich(
                        TextSpan(
                          style: t.bodyMedium?.copyWith(
                            color: DesignTokens.neutral11,
                            height: 1.35,
                            fontSize: 16,
                          ),
                          children: const [
                            TextSpan(text: 'Bạn có muốn bật chế độ '),
                            TextSpan(
                              text: 'Dỗ dành',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(
                              text:
                                  '? Peekie sẽ phát nhạc và bật màn hình biểu cảm ',
                            ),
                            TextSpan(
                              text: 'Dỗ dành',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(text: ' bé yêu.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        PeekieImageAssets.peekieKhoc,
                        height: 190,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onSoothing();
                          },
                          icon: PeekieAssetIcon(
                            PeekieIconAssets.cloudSharp,
                            size: 22,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Bật chế độ Dỗ dành',
                            style: t.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: DesignTokens.neutral12,
                            foregroundColor: Colors.white,
                            textStyle: t.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDismiss();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFCCE6FF),
                            foregroundColor: DesignTokens.neutral12,
                            textStyle: t.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Không, cảm ơn',
                            style: t.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: DesignTokens.neutral12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF9D99D),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 6),
              ),
              child: Center(
                child: PeekieAssetIcon(
                  PeekieIconAssets.moodCry,
                  size: 28,
                  color: DesignTokens.neutral12,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showPeekieNoiseDialog(
  BuildContext context, {
  required VoidCallback onAck,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 44, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Môi trường quá ồn ào',
                        textAlign: TextAlign.center,
                        style: t.headlineLarge?.copyWith(
                          color: DesignTokens.neutral12,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Âm thanh xung quanh có thể làm bé khó ngủ. Hãy thử giảm âm lượng, đóng cửa phòng để cải thiện không gian cho bé.',
                        textAlign: TextAlign.center,
                        style: t.bodyMedium?.copyWith(
                          color: DesignTokens.neutral11,
                          height: 1.35,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        PeekieImageAssets.peekieGianDu,
                        height: 230,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onAck();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: DesignTokens.neutral12,
                            foregroundColor: Colors.white,
                            textStyle: t.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Tôi đã kiểm tra, cảm ơn',
                            style: t.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF6C9CB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 6),
              ),
              child: Center(
                child: PeekieAssetIcon(
                  PeekieIconAssets.triangleDanger,
                  size: 28,
                  color: DesignTokens.neutral12,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Sets hardware notify for expression when user picks a quick mood (best-effort).
Future<void> notifyExpressionIfEnabled(
  BuildContext context,
  String channel,
) async {
  if (!context.mounted) return;
  try {
    await context.read<CameraProvider>().notifyHardware(channel);
    await MqttService.instance.publishEmotionVideo(channel);
  } catch (e) {
    debugPrint('[Emotion] mqtt error: $e');
  }
}
