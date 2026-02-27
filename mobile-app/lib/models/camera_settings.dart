/// Model lưu cấu hình camera RTSP (IP, user, password).
class CameraSettings {
  final String ip;
  final String username;
  final String password;
  final int port;
  final String path;

  const CameraSettings({
    required this.ip,
    required this.username,
    required this.password,
    this.port = 554,
    this.path = '/live/ch00_0',
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
      };

  factory CameraSettings.fromJson(Map<String, dynamic> json) {
    return CameraSettings(
      ip: json['ip'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 554,
      path: json['path'] as String? ?? '/live/ch00_0',
    );
  }

  CameraSettings copyWith({
    String? ip,
    String? username,
    String? password,
    int? port,
    String? path,
  }) {
    return CameraSettings(
      ip: ip ?? this.ip,
      username: username ?? this.username,
      password: password ?? this.password,
      port: port ?? this.port,
      path: path ?? this.path,
    );
  }
}
