import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt_server;

class MqttService {
  MqttService._();
  static final MqttService instance = MqttService._();

  // ===== CONFIG =====
  static const String host = 'mqtt.goads.com.vn';
  static const int port = 1883;

  // Server của bạn dùng mqtt:// (TCP thuần) trên 1883
  static const bool useWebSocket = false;

  // ⚠️ đổi nếu server bạn dùng path khác
  static const String websocketPath = '/mqtt';

  static const bool verboseLogs = true;

  static const String videoTopic = 'device/babycam/babycam/video';
  static const String brightnessTopic = 'device/babycam/babycam/brightness';
  static const String videoBasePath = '/home/babycam/videos/';

  mqtt_server.MqttServerClient? _client;
  Completer<void>? _connectCompleter;
  int _connectAttempt = 0;

  bool get isConnected =>
      _client?.connectionStatus?.state == mqtt.MqttConnectionState.connected;

  // ===== LOG =====
  void _log(String message) {
    if (!verboseLogs) return;
    final ts = DateTime.now().toIso8601String();
    debugPrint('[$ts][MQTT] $message');
  }

  void _logError(String message, Object error, [StackTrace? st]) {
    if (!verboseLogs) return;
    final ts = DateTime.now().toIso8601String();
    debugPrint('[$ts][MQTT][ERR] $message: $error');
    if (st != null) debugPrint(st.toString());
  }

  String _statusString(mqtt_server.MqttServerClient client) {
    final s = client.connectionStatus;
    return 'state=${s?.state} returnCode=${s?.returnCode}';
  }

  // ===== CONNECT =====
  Future<bool> ensureConnected() async {
    if (isConnected) return true;

    if (_connectCompleter != null) {
      try {
        await _connectCompleter!.future;
        return isConnected;
      } catch (_) {
        return false;
      }
    }

    _connectCompleter = Completer<void>();

    try {
      final clientId = _clientId();

      // TCP: hostname bình thường. WS: uri ws://host/path (port set ở client.port)
      final server = useWebSocket ? 'ws://$host$websocketPath' : host;

      final client = mqtt_server.MqttServerClient(server, clientId);

      client.port = port;
      client.keepAlivePeriod = 60;
      // Some brokers are strict about protocol negotiation; pin to MQTT v3.1.1.
      // (If your broker is MQTT v5-only, we should migrate to mqtt5_client.)
      client.setProtocolV311();

      client.connectTimeoutPeriod = 20000;
      // IMPORTANT: mqtt_client autoReconnect can surface socket errors as
      // unhandled exceptions on some Android/broker combos (RST by peer).
      // We reconnect explicitly via ensureConnected() before publish instead.
      client.autoReconnect = false;
      client.resubscribeOnAutoReconnect = false;

      client.logging(on: false);

      client.onConnected = _onConnected;
      client.onDisconnected = _onDisconnected;
      client.pongCallback = _onPong;

      if (useWebSocket) {
        client.useWebSocket = true;

        // quan trọng cho handshake
        client.websocketProtocols =
            mqtt.MqttClientConstants.protocolsMultipleDefault;
      }

      // Keep the CONNECT simple & standards-compliant; some brokers drop connections
      // when Will QoS is set without a will topic/message.
      final connMess = mqtt.MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .keepAliveFor(client.keepAlivePeriod);

      client.connectionMessage = connMess;

      _client = client;
      _connectAttempt++;

      _log(
        'connect begin attempt=$_connectAttempt '
        'mode=${useWebSocket ? "ws" : "tcp"} '
        'server=$server port=$port clientId=$clientId',
      );

      final sw = Stopwatch()..start();

      await client.connect();

      sw.stop();

      if (!isConnected) {
        _log(
          'connect failed ${sw.elapsedMilliseconds}ms ${_statusString(client)}',
        );
        _client?.disconnect();
        _client = null;
        _connectCompleter?.complete();
        return false;
      }

      _log(
        'connect SUCCESS ${sw.elapsedMilliseconds}ms ${_statusString(client)}',
      );

      _connectCompleter?.complete();
      return true;
    } catch (e, st) {
      _logError('connect exception', e, st);
      _client?.disconnect();
      _client = null;
      _connectCompleter?.complete();
      return false;
    } finally {
      _connectCompleter = null;
    }
  }

  // ===== PUBLISH =====
  Future<void> publishVideoPath(String absolutePath) async {
    try {
      final ok = await ensureConnected();
      if (!ok) {
        _log('publish skipped (not connected)');
        return;
      }

      final client = _client;
      if (client == null || !isConnected) return;

      final payload = jsonEncode({'path': absolutePath});
      final builder = mqtt.MqttClientPayloadBuilder()..addString(payload);

      client.publishMessage(
        videoTopic,
        mqtt.MqttQos.atLeastOnce,
        builder.payload!,
      );

      _log('publish OK topic=$videoTopic payload=$payload');
    } catch (e, st) {
      _logError('publish exception', e, st);
    }
  }

  /// [brightness] 0–100. Payload JSON: `{"brightness":100}`.
  Future<void> publishBrightness(int brightness) async {
    try {
      final ok = await ensureConnected();
      if (!ok) {
        _log('publish brightness skipped (not connected)');
        return;
      }

      final client = _client;
      if (client == null || !isConnected) return;

      final b = brightness.clamp(0, 100);
      final payload = jsonEncode({'brightness': b});
      final builder = mqtt.MqttClientPayloadBuilder()..addString(payload);

      client.publishMessage(
        brightnessTopic,
        mqtt.MqttQos.atLeastOnce,
        builder.payload!,
      );

      _log('publish OK topic=$brightnessTopic payload=$payload');
    } catch (e, st) {
      _logError('publish brightness exception', e, st);
    }
  }

  // ===== BUSINESS LOGIC =====
  Future<void> publishEmotionVideo(String channelId) async {
    final id = channelId.toLowerCase().trim();

    final file = switch (id) {
      'buon_ngu' || 'sleepy' => 'buon_ngu.mp4',
      'ham_mo' || 'playful' => 'ham_mo.mp4',
      'vui_mung' || 'happy' => 'vui_mung.mp4',
      _ => null,
    };

    if (file == null) {
      _log('skip (no mapping) channel=$channelId');
      return;
    }

    _log('emotion $channelId -> $file');

    await publishVideoPath('$videoBasePath$file');
  }

  // ===== DISCONNECT =====
  Future<void> disconnect() async {
    _log('disconnect');
    _client?.disconnect();
    _client = null;
  }

  // ===== EVENTS =====
  void _onConnected() {
    _log('onConnected');
  }

  void _onDisconnected() {
    _log('onDisconnected');
    _client = null;
  }

  void _onPong() {
    _log('pong');
  }

  // ===== CLIENT ID =====
  String _clientId() {
    return 'babycare_${DateTime.now().millisecondsSinceEpoch}';
  }
}
