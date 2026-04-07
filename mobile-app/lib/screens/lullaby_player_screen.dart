import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/peekie_icon_assets.dart';
import '../models/song.dart';
import '../providers/music_player_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/peekie_asset_icon.dart';
import '../widgets/peekie_home_widgets.dart';

class LullabyPlayerScreen extends StatefulWidget {
  const LullabyPlayerScreen({super.key});

  @override
  State<LullabyPlayerScreen> createState() => _LullabyPlayerScreenState();
}

class _LullabyPlayerScreenState extends State<LullabyPlayerScreen> {
  SongCategory? _selectedCategory;
  String _query = '';

  static const Color _searchBg = Color(0xFFF2F4F8);
  static const Color _searchBorder = Color(0xFFDDE1E6);

  String _formatDurationLabel(Duration duration) {
    final totalMinutes = duration.inMinutes;
    if (totalMinutes >= 60) {
      final hours = (totalMinutes / 60).round();
      return '$hours tiếng';
    }
    return '$totalMinutes phút';
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

  List<Song> get _filteredSongs {
    final q = _query.trim().toLowerCase();
    final songs = context.read<MusicPlayerProvider>().songs;
    return songs.where((s) {
      final catOk =
          _selectedCategory == null || s.category == _selectedCategory;
      final qOk = q.isEmpty || s.title.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList(growable: false);
  }

  Future<void> _togglePlayFor(Song song) async {
    final player = context.read<MusicPlayerProvider>();
    final isSame = player.currentSong.id == song.id;
    if (isSame) {
      await player.togglePlayPause();
    } else {
      await player.playSong(song);
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = _filteredSongs;
    final player = context.watch<MusicPlayerProvider>();
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
                  PeekieTopBar(
                    onBack: () => Navigator.maybePop(context),
                    onSettings: () => Navigator.pushNamed(context, '/settings'),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Banner: toàn bộ nội dung nằm trong PNG — không ghép Text/ảnh để tránh chồng lớp.
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {},
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                PeekieImageAssets.theGioiCoTichChoBe,
                                width: double.infinity,
                                fit: BoxFit.fitWidth,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.medium,
                                gaplessPlayback: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: _searchBg,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: _searchBorder, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: _searchBorder, width: 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FilterChip(
                                label: 'Tất cả',
                                selected: _selectedCategory == null,
                                onSelected: (_) =>
                                    setState(() => _selectedCategory = null),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Tiếng ồn trắng',
                                selected: _selectedCategory ==
                                    SongCategory.whiteNoise,
                                onSelected: (_) => setState(() =>
                                    _selectedCategory =
                                        SongCategory.whiteNoise),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Hát ru',
                                selected:
                                    _selectedCategory == SongCategory.lullaby,
                                onSelected: (_) => setState(() =>
                                    _selectedCategory = SongCategory.lullaby),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Truyện cổ',
                                selected:
                                    _selectedCategory == SongCategory.fairyTale,
                                onSelected: (_) => setState(() =>
                                    _selectedCategory = SongCategory.fairyTale),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Song Cards List
                  Expanded(
                    child: songs.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Không có nội dung phù hợp.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: DesignTokens.neutral10,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 24,
                            ),
                            itemCount: songs.length,
                            itemBuilder: (context, index) {
                              final song = songs[index];
                              final isCurrent =
                                  player.currentSong.id == song.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: _SongCard(
                                  song: song,
                                  isPlaying: isCurrent && player.isPlaying,
                                  onTap: () => _togglePlayFor(song),
                                  subtitle:
                                      '${_categoryLabel(song.category)} • ${_formatDurationLabel(song.duration)}',
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              // Floating bottom navigation bar
              const CustomBottomNavBar(currentRoute: '/lullaby'),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: DesignTokens.neutral12,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : DesignTokens.neutral12,
            fontWeight: FontWeight.w700,
          ),
      backgroundColor: DesignTokens.neutral4,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _SongCard extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final String subtitle;

  const _SongCard({
    required this.song,
    required this.isPlaying,
    required this.onTap,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bg = isPlaying ? const Color(0xFFE6F2FF) : Colors.transparent;
    final shadow = isPlaying
        ? [
            BoxShadow(
              color: DesignTokens.neutral12.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
        : const <BoxShadow>[];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: shadow,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    song.thumbnailAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.neutral12,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(
                        color: DesignTokens.neutral10,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _PlayCircleButton(
                isPlaying: isPlaying,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayCircleButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  static const double _size = 45;

  const _PlayCircleButton({
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Center(
            // `pause.png` là icon tròn + glyph trong 1 PNG → hiển thị raw.
            child: isPlaying
                ? const PeekieAssetIcon(
                    PeekieMusicNenIcons.pause,
                    size: _size,
                  )
                : Container(
                    width: _size,
                    height: _size,
                    decoration: const BoxDecoration(
                      color: DesignTokens.neutral12,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
