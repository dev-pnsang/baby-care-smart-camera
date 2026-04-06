/// Icon PNG cho **khối nhạc nền** (điều khiển phát / âm lượng).
/// Đường dẫn khớp file trong `assets/icons/`.
abstract final class PeekieMusicNenIcons {
  /// Nút tròn + glyph trong một PNG — hiển thị raw, không tint.
  static const String pause = 'assets/icons/pause.png';
  static const String playSkipBackCircle =
      'assets/icons/play-skip-back-circle.png';
  static const String playSkipForwardCircle =
      'assets/icons/play-skip-forward-circle.png';
  static const String volumeHigh = 'assets/icons/volume-high.png';
}

/// PNG icons in `assets/icons/` (design export).
abstract final class PeekieIconAssets {
  static const String _root = 'assets/icons';

  static const String record = '$_root/record-circle.png';
  static const String camera = '$_root/camera-fill.png';
  static const String microphone = '$_root/microphone.png';

  /// Cùng file với [PeekieMusicNenIcons.volumeHigh] (thanh camera + card nhạc).
  static const String volumeHigh = PeekieMusicNenIcons.volumeHigh;
  static const String volumeMedium = '$_root/volume-medium.png';
  static const String pictureInPicture = '$_root/picture-in-picture-on.png';

  static const String musicNote = '$_root/music-note-03.png';
  static const String playlist = '$_root/playlist-03.png';

  static const String skipBack = PeekieMusicNenIcons.playSkipBackCircle;
  static const String skipForward = PeekieMusicNenIcons.playSkipForwardCircle;
  static const String pause = PeekieMusicNenIcons.pause;

  static const String cloud = '$_root/cloud.png';
  static const String temperature = '$_root/temperature.png';
  /// Water droplet (file name `Vector.png`).
  static const String humidity = '$_root/Vector.png';

  static const String happy = '$_root/happy-01.png';
  static const String happyAlt = '$_root/happy-02.png';
  static const String relieved = '$_root/relieved-01.png';
  static const String autoMode = '$_root/artificial-intelligence-08.png';
  static const String customize = '$_root/preference-horizontal.png';
  /// Top bar settings (toolbar).
  static const String settingsToolbar = '$_root/Huge-icon.png';
  static const String share01 = '$_root/share-01.png';
  static const String elements = '$_root/elements.png';
}

/// Ảnh minh họa / cover trong app.
abstract final class PeekieImageAssets {
  static const String muaRoiTiTach = 'assets/images/mua_roi_ti_tach.png';
  static const String backgroundNhacNen = 'assets/images/background_nhac_nen.png';
  static const String tiengSuoiRocRach = 'assets/images/tieng_suoi_roc_rach.png';
  static const String theGioiCoTichChoBe =
      'assets/images/the_gioi_co_tich_cho_be.png';
  static const String auOViDau = 'assets/images/au_o_vi_dau.png';
  static const String thanhGiong = 'assets/images/thanh_giong.png';
  static const String truyenCoBeLoLem =
      'assets/images/truyen_co_be_lo_lem.png';
}
