import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/camera_provider.dart';
import '../theme/design_tokens.dart';

class PeekieCustomizeEmotionItem {
  const PeekieCustomizeEmotionItem({
    required this.label,
    required this.assetName,
    required this.channelId,
  });

  final String label;
  final String assetName;
  final String channelId;

  String get assetPath => 'assets/emotion/$assetName';
}

const List<PeekieCustomizeEmotionItem> kPeekieCustomizeEmotions = [
  PeekieCustomizeEmotionItem(
    label: 'Tự động',
    assetName: 'tu_dong.png',
    channelId: 'tu_dong',
  ),
  PeekieCustomizeEmotionItem(
    label: 'Thư giãn',
    assetName: 'thu_gian.png',
    channelId: 'thu_gian',
  ),
  PeekieCustomizeEmotionItem(
    label: 'Hâm mộ',
    assetName: 'ham_mo.png',
    channelId: 'ham_mo',
  ),
  PeekieCustomizeEmotionItem(
    label: 'Vui mừng',
    assetName: 'vui_mung.png',
    channelId: 'vui_mung',
  ),
  PeekieCustomizeEmotionItem(
    label: 'Tò mò',
    assetName: 'to_mo.png',
    channelId: 'to_mo',
  ),
  PeekieCustomizeEmotionItem(
    label: 'Buồn ngủ',
    assetName: 'buon_ngu.png',
    channelId: 'buon_ngu',
  ),
  PeekieCustomizeEmotionItem(
    label: 'Lạnh lẽo',
    assetName: 'lanh_leo.png',
    channelId: 'lanh_leo',
  ),
  PeekieCustomizeEmotionItem(
    label: 'Nóng nực',
    assetName: 'nong_nuc.png',
    channelId: 'nong_nuc',
  ),
  PeekieCustomizeEmotionItem(
    label: 'Lo sợ',
    assetName: 'lo_so.png',
    channelId: 'lo_so',
  ),
];

/// Full-screen overlay + bottom sheet matching `Tuỳ chỉnh màn hình` mockup.
Future<void> showPeekieExpressionCustomizeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (ctx) => const _PeekieCustomizeOverlay(),
  );
}

class _PeekieCustomizeOverlay extends StatefulWidget {
  const _PeekieCustomizeOverlay();

  @override
  State<_PeekieCustomizeOverlay> createState() =>
      _PeekieCustomizeOverlayState();
}

class _PeekieCustomizeOverlayState extends State<_PeekieCustomizeOverlay> {
  static const String _heroAsset = 'assets/images/PEEKIE_vui_ve.png';

  double _brightness = 0.7;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        kPeekieCustomizeEmotions.indexWhere((e) => e.channelId == 'vui_mung');
    if (_selectedIndex < 0) _selectedIndex = 0;
  }

  Future<void> _applyEmotion(PeekieCustomizeEmotionItem option) async {
    if (!mounted) return;
    try {
      await context.read<CameraProvider>().notifyHardware(option.channelId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final titleStyle = GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: DesignTokens.neutral12,
    );
    final sectionStyle = GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: DesignTokens.neutral12,
    );
    final labelStyle = GoogleFonts.nunito(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: DesignTokens.neutral12,
      height: 1.05,
    );

    /// Bố cục giống mockup `Tuỳ chỉnh màn hình.png`: phần trên = nền mờ + Peekie (tự scale
    /// trong [Expanded]), phần dưới = panel trắng — không dùng Stack để tránh ảnh đè header.
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: size.height,
        width: size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: ColoredBox(
                  color: Colors.black.withOpacity(0.35),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Center(
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: Image.asset(
                                _heroAsset,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                gaplessPlayback: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.white,
              elevation: 12,
              shadowColor: Colors.black26,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.close,
                                    size: 22,
                                    color: DesignTokens.neutral12,
                                  ),
                                ),
                              ),
                            ),
                            Text('Tuỳ chỉnh nâng cao', style: titleStyle),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Độ sáng', style: sectionStyle),
                          Text(
                            '${(_brightness * 100).round()}%',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: DesignTokens.neutral12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/sunny.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: DesignTokens.neutral12,
                                inactiveTrackColor: DesignTokens.neutral4,
                                thumbColor: Colors.white,
                                overlayColor:
                                    DesignTokens.babyBlue5.withOpacity(0.2),
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                  elevation: 1,
                                ),
                              ),
                              child: Slider(
                                value: _brightness,
                                onChanged: (v) =>
                                    setState(() => _brightness = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Biểu cảm', style: sectionStyle),
                      ),
                      const SizedBox(height: 4),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 6,
                          // Cao hơn → ô thấp hơn, gom các hàng lại (không dùng Expanded trong ô).
                          childAspectRatio: 1.14,
                        ),
                        itemCount: kPeekieCustomizeEmotions.length,
                        itemBuilder: (context, index) {
                          final item = kPeekieCustomizeEmotions[index];
                          final selected = index == _selectedIndex;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedIndex = index);
                              _applyEmotion(item);
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final w = constraints.maxWidth;
                                final maxH = constraints.maxHeight;
                                // Giữ chỗ cho 2 dòng nhãn; không dùng Expanded để tránh khoảng trống giữa các hàng.
                                final iconH = math.min(
                                  w * 0.82,
                                  math.max(32.0, maxH - 22),
                                );
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: iconH,
                                      width: w,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        child: Image.asset(
                                          item.assetPath,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.bottomCenter,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.sentiment_satisfied_alt,
                                            color: DesignTokens.neutral9,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      item.label,
                                      style: labelStyle.copyWith(
                                        fontWeight: selected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: selected
                                            ? DesignTokens.babyBlue6
                                            : DesignTokens.neutral12,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
