import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../widgets/neumorphic_button.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class LullabyPlayerScreen extends StatefulWidget {
  const LullabyPlayerScreen({super.key});

  @override
  State<LullabyPlayerScreen> createState() => _LullabyPlayerScreenState();
}

class _LullabyPlayerScreenState extends State<LullabyPlayerScreen> {
  final List<Song> _songs = [
    Song(
      id: '1',
      title: 'Ru Con Ngủ',
      artist: 'Nhạc thiếu nhi',
      icon: '🌙',
      duration: const Duration(minutes: 3, seconds: 45),
    ),
    Song(
      id: '2',
      title: 'Ru Con Ngủ',
      artist: 'Nhạc thiếu nhi',
      icon: '🌙',
      duration: const Duration(minutes: 4, seconds: 20),
    ),
    Song(
      id: '3',
      title: 'Tiếng Sóng Biển',
      artist: 'Nhạc thiếu nhi',
      icon: '🐑',
      duration: const Duration(minutes: 3, seconds: 15),
    ),
    Song(
      id: '4',
      title: 'Tiếng Ồn Trắng',
      artist: 'Nhạc thiếu nhi',
      icon: '⭐',
      duration: const Duration(minutes: 5, seconds: 10),
    ),
    Song(
      id: '5',
      title: 'Nhạc Thư Xận',
      artist: 'Nhạc thiếu nhi',
      icon: '🎶',
      duration: const Duration(minutes: 4, seconds: 30),
    ),
  ];

  Song? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentSong = _songs[0];
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
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
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        NeumorphicButton(
                          width: 50,
                          height: 50,
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: AppTheme.textDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Âm nhạc cho Bé',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Song Cards List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 100,
                      ),
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        final isCurrent = _currentSong?.id == song.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SongCard(
                            song: song,
                            isCurrent: isCurrent,
                            index: index,
                            onTap: () {
                              setState(() {
                                _currentSong = song;
                                _isPlaying = true;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // Player UI (Floating Panel)
                  if (_currentSong != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        bottom: 100.0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.glassSurface,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Song Info
                                Row(
                                  children: [
                                    Text(
                                      _currentSong!.icon,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _currentSong!.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          Text(
                                            _currentSong!.artist,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Progress Bar
                                Stack(
                                  children: [
                                    Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: _currentPosition.inSeconds /
                                          (_currentSong!.duration.inSeconds > 0
                                              ? _currentSong!.duration.inSeconds
                                              : 1),
                                      child: Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.progressGradient,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _formatDuration(_currentPosition),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        _formatDuration(_currentSong!.duration),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textLight,
                                        ),
                                        textAlign: TextAlign.end,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Controls
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final screenWidth = constraints.maxWidth;
                                    final isSmallScreen = screenWidth < 300;
                                    final buttonSize = isSmallScreen ? 45.0 : 50.0;
                                    final playButtonSize = isSmallScreen ? 60.0 : 70.0;
                                    final spacing = isSmallScreen ? 12.0 : 20.0;
                                    
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        NeumorphicButton(
                                          width: buttonSize,
                                          height: buttonSize,
                                          onPressed: () {
                                            // Previous song
                                          },
                                          child: Icon(
                                            Icons.skip_previous,
                                            color: AppTheme.textDark,
                                            size: isSmallScreen ? 20 : 24,
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        NeumorphicButton(
                                          width: playButtonSize,
                                          height: playButtonSize,
                                          isActive: _isPlaying,
                                          onPressed: () {
                                            setState(() {
                                              _isPlaying = !_isPlaying;
                                            });
                                          },
                                          child: Icon(
                                            _isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            color: AppTheme.primaryBlue,
                                            size: isSmallScreen ? 28 : 32,
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        NeumorphicButton(
                                          width: buttonSize,
                                          height: buttonSize,
                                          onPressed: () {
                                            // Next song
                                          },
                                          child: Icon(
                                            Icons.skip_next,
                                            color: AppTheme.textDark,
                                            size: isSmallScreen ? 20 : 24,
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        NeumorphicButton(
                                          width: buttonSize,
                                          height: buttonSize,
                                          onPressed: () {
                                            // Shuffle/Repeat
                                          },
                                          child: Icon(
                                            Icons.shuffle,
                                            color: AppTheme.textDark,
                                            size: isSmallScreen ? 18 : 20,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Volume Control
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.volume_up,
                                      color: AppTheme.textLight,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: FractionallySizedBox(
                                          widthFactor: 0.7,
                                          child: Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              gradient: AppTheme.progressGradient,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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

class _SongCard extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final int index;
  final VoidCallback onTap;

  const _SongCard({
    required this.song,
    required this.isCurrent,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onPressed: onTap,
      isActive: isCurrent,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  song.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            // Play Button or Arrow
            index == 0
                ? Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textLight,
                    size: 20,
                  )
                : NeumorphicButton(
                    width: 45,
                    height: 45,
                    onPressed: onTap,
                    child: Icon(
                      isCurrent ? Icons.pause : Icons.play_arrow,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

