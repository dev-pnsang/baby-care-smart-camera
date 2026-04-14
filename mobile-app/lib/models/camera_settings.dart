/// Model lưu cấu hình camera RTSP (IP, user, password).
class CameraSettings {
  static int _readInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  final String ip;
  final String username;
  final String password;
  final int port;
  final String path;

  /// Ngưỡng tối thiểu (%) xác suất class *crying* để coi là khóc (mặc định 60).
  final int cryDetectMinPercent;

  /// Ngưỡng tối đa (%) xác suất *crying*: nếu prob khóc **dưới** mức này → coi là noise ngay (mặc định 50).
  /// Phải nhỏ hơn [cryDetectMinPercent].
  final int noiseDetectMaxPercent;

  /// Khoảng thời gian (giây) giữa mỗi lần lấy mẫu âm thanh từ RTSP để phân tích (mặc định 5).
  final int soundCheckIntervalSeconds;

  const CameraSettings({
    required this.ip,
    required this.username,
    required this.password,
    this.port = 554,
    this.path = '/live/ch00_0',
    this.cryDetectMinPercent = 60,
    this.noiseDetectMaxPercent = 50,
    this.soundCheckIntervalSeconds = 5,
  });

  bool get isValid =>
      ip.trim().isNotEmpty && username.trim().isNotEmpty && password.isNotEmpty;

  /// Tạo URL RTSP dạng: rtsp://user:password@ip:port/path
  String get rtspUrl {
    final user = Uri.encodeComponent(username.trim());
    final pass = Uri.encodeComponent(password);
    final host = ip.trim();
    final pathNormalized = path.startsWith('/') ? path : '/$path';
    return 'rtsp://$user:$pass@$host:$port$pathNormalized';
  }

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'username': username,
        'password': password,
        'port': port,
        'path': path,
        'cryDetectMinPercent': cryDetectMinPercent,
        'noiseDetectMaxPercent': noiseDetectMaxPercent,
        'soundCheckIntervalSeconds': soundCheckIntervalSeconds,
      };

  factory CameraSettings.fromJson(Map<String, dynamic> json) {
    return CameraSettings(
      ip: json['ip'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      port: _readInt(json['port'], 554),
      path: json['path'] as String? ?? '/live/ch00_0',
      cryDetectMinPercent: _readInt(json['cryDetectMinPercent'], 60),
      noiseDetectMaxPercent: _readInt(json['noiseDetectMaxPercent'], 50),
      soundCheckIntervalSeconds: _readInt(json['soundCheckIntervalSeconds'], 5),
    );
  }

  CameraSettings copyWith({
    String? ip,
    String? username,
    String? password,
    int? port,
    String? path,
    int? cryDetectMinPercent,
    int? noiseDetectMaxPercent,
    int? soundCheckIntervalSeconds,
  }) {
    return CameraSettings(
      ip: ip ?? this.ip,
      username: username ?? this.username,
      password: password ?? this.password,
      port: port ?? this.port,
      path: path ?? this.path,
      cryDetectMinPercent: cryDetectMinPercent ?? this.cryDetectMinPercent,
      noiseDetectMaxPercent:
          noiseDetectMaxPercent ?? this.noiseDetectMaxPercent,
      soundCheckIntervalSeconds:
          soundCheckIntervalSeconds ?? this.soundCheckIntervalSeconds,
    );
  }
}
