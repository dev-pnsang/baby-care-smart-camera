import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/design_tokens.dart';
import '../providers/camera_provider.dart';
import '../services/mqtt_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/peekie_expression_customize_sheet.dart';

class ExpressionControllerScreen extends StatefulWidget {
  const ExpressionControllerScreen({super.key});

  @override
  State<ExpressionControllerScreen> createState() =>
      _ExpressionControllerScreenState();
}

class _ExpressionControllerScreenState
    extends State<ExpressionControllerScreen> {
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        kPeekieCustomizeEmotions.indexWhere((e) => e.channelId == 'vui_mung');
    if (_selectedIndex < 0) _selectedIndex = 0;
  }

  Future<void> _handleExpressionTap(PeekieCustomizeEmotionItem item) async {
    setState(() {
      _selectedIndex = kPeekieCustomizeEmotions.indexWhere(
        (e) => e.channelId == item.channelId,
      );
    });

    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);

    // Notify hardware with expression ID and trigger sound effect
    await cameraProvider.notifyHardware(item.channelId);
    try {
      await MqttService.instance.publishEmotionVideo(item.channelId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: DesignTokens.neutral1, // #FDFDFD
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
                            style: t.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: DesignTokens.neutral12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expression Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: kPeekieCustomizeEmotions.length,
                        itemBuilder: (context, index) {
                          final item = kPeekieCustomizeEmotions[index];
                          final selected = index == _selectedIndex;
                          return _EmotionTile(
                            label: item.label,
                            assetPath: item.assetPath,
                            selected: selected,
                            onTap: () => _handleExpressionTap(item),
                          );
                        },
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

class _EmotionTile extends StatelessWidget {
  const _EmotionTile({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final border = selected ? DesignTokens.babyBlue7 : Colors.transparent;
    final bg = selected ? const Color(0xFFEAF4FF) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.neutral12.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                        color: DesignTokens.neutral12,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: DesignTokens.babyBlue7,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
