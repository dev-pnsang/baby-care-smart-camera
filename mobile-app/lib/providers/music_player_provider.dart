import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../theme/peekie_icon_assets.dart';

class MusicPlayerProvider extends ChangeNotifier {
  MusicPlayerProvider() {
    _songs = [
      Song(
        id: '1',
        title: 'Mưa rơi tí tách',
        category: SongCategory.whiteNoise,
        thumbnailAsset: PeekieImageAssets.muaRoiTiTach,
        audioAsset: 'audio/mua_roi_ti_tach.MP3',
        duration: const Duration(hours: 1),
      ),
      Song(
        id: '2',
        title: 'Ầu ơ ví dầu',
        category: SongCategory.lullaby,
        thumbnailAsset: PeekieImageAssets.auOViDau,
        audioAsset: 'audio/au_o_vi_dau.mp3',
        duration: const Duration(hours: 1),
      ),
      Song(
        id: '3',
        title: 'Tiếng suối róc rách',
        category: SongCategory.whiteNoise,
        thumbnailAsset: PeekieImageAssets.tiengSuoiRocRach,
        audioAsset: 'audio/tieng_suoi_roc_rach.mp3',
        duration: const Duration(hours: 1),
      ),
      Song(
        id: '4',
        title: 'Thánh Gióng',
        category: SongCategory.fairyTale,
        thumbnailAsset: PeekieImageAssets.thanhGiong,
        audioAsset: 'audio/thanh_giong.mp3',
        duration: const Duration(minutes: 20),
      ),
      Song(
        id: '5',
        title: 'Truyện Cô bé Lọ Lem',
        category: SongCategory.fairyTale,
        thumbnailAsset: PeekieImageAssets.truyenCoBeLoLem,
        audioAsset: 'audio/co_be_lo_lem.mp3',
        duration: const Duration(minutes: 20),
      ),
    ];

    _currentIndex = 0;
    _wirePlayer();
  }

  final AudioPlayer _player = AudioPlayer();

  late final StreamSubscription<void> _completeSub;
  late final StreamSubscription<Duration> _posSub;
  late final StreamSubscription<Duration> _durSub;
  late final StreamSubscription<PlayerState> _stateSub;

  late List<Song> _songs;
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _actualDuration = Duration.zero;
  String? _loadedSongId;
  double _volume = 1.0;
  double _lastNonZeroVolume = 0.7;

  List<Song> get songs => List.unmodifiable(_songs);
  int get currentIndex => _currentIndex;
  Song get currentSong => _songs[_currentIndex];
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration =>
      _actualDuration > Duration.zero ? _actualDuration : currentSong.duration;
  double get volume => _volume;
  bool get isMuted => _volume == 0;

  double get progress {
    final d = duration.inMilliseconds;
    if (d <= 0) return 0;
    return (_position.inMilliseconds / d).clamp(0.0, 1.0);
  }

  void _wirePlayer() {
    _completeSub = _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      notifyListeners();
    });
    _posSub = _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });
    _durSub = _player.onDurationChanged.listen((d) {
      _actualDuration = d;
      notifyListeners();
    });
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      final playing = s == PlayerState.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
  }

  Future<void> playSong(Song song) async {
    final idx = _songs.indexWhere((s) => s.id == song.id);
    if (idx == -1) return;
    await playAt(idx);
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _songs.length) return;
    _currentIndex = index;
    _position = Duration.zero;
    _actualDuration = Duration.zero;

    final song = currentSong;
    await _player.stop();
    await _player.setVolume(_volume);
    await _player.play(AssetSource(song.audioAsset));
    _loadedSongId = song.id;
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_songs.isEmpty) return;
    final song = currentSong;
    if (_isPlaying) {
      await _player.pause();
      _isPlaying = false;
      notifyListeners();
      return;
    }
    if (_loadedSongId == song.id) {
      await _player.resume();
    } else {
      await _player.play(AssetSource(song.audioAsset));
      _loadedSongId = song.id;
    }
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> next() async {
    if (_songs.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _songs.length;
    await playAt(nextIndex);
  }

  Future<void> previous() async {
    if (_songs.isEmpty) return;
    if (_position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    final prevIndex = (_currentIndex - 1) < 0 ? _songs.length - 1 : _currentIndex - 1;
    await playAt(prevIndex);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _position = position;
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    final clamped = v.clamp(0.0, 1.0);
    _volume = clamped;
    if (_volume > 0) _lastNonZeroVolume = _volume;
    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (isMuted) {
      await setVolume(_lastNonZeroVolume.clamp(0.1, 1.0));
    } else {
      await setVolume(0);
    }
  }

  @override
  Future<void> dispose() async {
    await _completeSub.cancel();
    await _posSub.cancel();
    await _durSub.cancel();
    await _stateSub.cancel();
    await _player.dispose();
    super.dispose();
  }
}

