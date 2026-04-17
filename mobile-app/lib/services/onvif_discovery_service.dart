import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/onvif_discovery.dart';

class OnvifDiscoveryService {
  static final InternetAddress _multicastAddress =
      InternetAddress('239.255.255.250');
  static const int _wsDiscoveryPort = 3702;

  /// WS-Discovery Probe to discover ONVIF devices on the LAN.
  ///
  /// Notes:
  /// - This uses UDP multicast; on some Android devices you may need multicast
  ///   permission/lock to receive replies reliably.
  Future<List<OnvifDiscoveredDevice>> discover({
    Duration timeout = const Duration(seconds: 3),
    Duration listenExtra = const Duration(milliseconds: 400),
  }) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
      reusePort: false,
    );

    final results = <String, OnvifDiscoveredDevice>{};
    final done = Completer<void>();

    Timer(timeout, () async {
      await Future<void>.delayed(listenExtra);
      if (!done.isCompleted) done.complete();
    });

    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final d = socket.receive();
      if (d == null) return;
      final payload = utf8.decode(d.data, allowMalformed: true);
      final device = _tryParseProbeMatch(payload);
      if (device == null) return;

      final key = device.endpointReference ??
          (device.xaddrs.isNotEmpty ? device.xaddrs.first.toString() : payload);
      results[key] = device;
    });

    socket.broadcastEnabled = true;

    final messageId = 'uuid:${_uuidLike()}';
    final probe = _buildProbe(messageId: messageId);
    final bytes = utf8.encode(probe);
    socket.send(bytes, _multicastAddress, _wsDiscoveryPort);

    await done.future;
    socket.close();

    return results.values.toList()
      ..sort((a, b) => (a.primaryHost ?? '').compareTo(b.primaryHost ?? ''));
  }

  /// Test ONVIF Device Service connectivity using HTTP Basic auth and simple
  /// Device service calls.
  ///
  /// This tries:
  /// - `GetCapabilities` (Device)
  /// - `GetDeviceInformation` (Device)
  Future<OnvifConnectionTestResult> testConnection({
    required OnvifDiscoveredDevice device,
    required String username,
    required String password,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final deviceService = _pickDeviceServiceXAddr(device.xaddrs);
    if (deviceService == null) {
      return OnvifConnectionTestResult(
        device: device,
        deviceService: null,
        ok: false,
        httpStatus: null,
        fault: 'No XAddr found from WS-Discovery response.',
        manufacturer: null,
        model: null,
        firmwareVersion: null,
        serialNumber: null,
        hardwareId: null,
      );
    }

    final auth = base64Encode(utf8.encode('$username:$password'));
    final headers = <String, String>{
      'Content-Type': 'application/soap+xml; charset=utf-8',
      'Authorization': 'Basic $auth',
    };

    try {
      // 1) GetCapabilities
      final capsResp = await http
          .post(
            deviceService,
            headers: headers,
            body: _soapEnvelope(
              body: '''
<tds:GetCapabilities xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
  <tds:Category>All</tds:Category>
</tds:GetCapabilities>
''',
            ),
          )
          .timeout(timeout);

      if (capsResp.statusCode >= 400) {
        return OnvifConnectionTestResult(
          device: device,
          deviceService: deviceService,
          ok: false,
          httpStatus: capsResp.statusCode,
          fault: _tryParseSoapFault(capsResp.body) ??
              'HTTP ${capsResp.statusCode} from device service.',
          manufacturer: null,
          model: null,
          firmwareVersion: null,
          serialNumber: null,
          hardwareId: null,
        );
      }

      // 2) GetDeviceInformation
      final infoResp = await http
          .post(
            deviceService,
            headers: headers,
            body: _soapEnvelope(
              body: '''
<tds:GetDeviceInformation xmlns:tds="http://www.onvif.org/ver10/device/wsdl" />
''',
            ),
          )
          .timeout(timeout);

      if (infoResp.statusCode >= 400) {
        return OnvifConnectionTestResult(
          device: device,
          deviceService: deviceService,
          ok: false,
          httpStatus: infoResp.statusCode,
          fault: _tryParseSoapFault(infoResp.body) ??
              'HTTP ${infoResp.statusCode} from device service.',
          manufacturer: null,
          model: null,
          firmwareVersion: null,
          serialNumber: null,
          hardwareId: null,
        );
      }

      final info = _tryParseDeviceInformation(infoResp.body);

      return OnvifConnectionTestResult(
        device: device,
        deviceService: deviceService,
        ok: true,
        httpStatus: infoResp.statusCode,
        fault: null,
        manufacturer: info?['Manufacturer'],
        model: info?['Model'],
        firmwareVersion: info?['FirmwareVersion'],
        serialNumber: info?['SerialNumber'],
        hardwareId: info?['HardwareId'],
      );
    } on TimeoutException {
      return OnvifConnectionTestResult(
        device: device,
        deviceService: deviceService,
        ok: false,
        httpStatus: null,
        fault: 'Timeout while contacting device service.',
        manufacturer: null,
        model: null,
        firmwareVersion: null,
        serialNumber: null,
        hardwareId: null,
      );
    } catch (e) {
      return OnvifConnectionTestResult(
        device: device,
        deviceService: deviceService,
        ok: false,
        httpStatus: null,
        fault: e.toString(),
        manufacturer: null,
        model: null,
        firmwareVersion: null,
        serialNumber: null,
        hardwareId: null,
      );
    }
  }

  static Uri? _pickDeviceServiceXAddr(List<Uri> xaddrs) {
    if (xaddrs.isEmpty) return null;
    // Most ONVIF devices advertise the Device service endpoint in XAddrs.
    // Prefer http(s) URL containing "device_service".
    final preferred = xaddrs.firstWhere(
      (u) =>
          (u.scheme == 'http' || u.scheme == 'https') &&
          u.path.toLowerCase().contains('device_service'),
      orElse: () => xaddrs.first,
    );
    return preferred;
  }

  static String _soapEnvelope({required String body}) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
            xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
            xmlns:wsa="http://www.w3.org/2005/08/addressing">
  <s:Header/>
  <s:Body>
$body
  </s:Body>
</s:Envelope>
''';
  }

  static String _buildProbe({required String messageId}) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<e:Envelope xmlns:e="http://www.w3.org/2003/05/soap-envelope"
            xmlns:w="http://schemas.xmlsoap.org/ws/2004/08/addressing"
            xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery"
            xmlns:dn="http://www.onvif.org/ver10/network/wsdl">
  <e:Header>
    <w:MessageID>$messageId</w:MessageID>
    <w:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</w:To>
    <w:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</w:Action>
  </e:Header>
  <e:Body>
    <d:Probe>
      <d:Types>dn:NetworkVideoTransmitter</d:Types>
    </d:Probe>
  </e:Body>
</e:Envelope>
''';
  }

  static OnvifDiscoveredDevice? _tryParseProbeMatch(String xml) {
    // Keep parsing lightweight and tolerant by using tag extraction rather
    // than strict XML namespace handling (many cameras are sloppy).
    final xaddrsText = _extractTagText(xml, 'XAddrs');
    if (xaddrsText == null || xaddrsText.trim().isEmpty) return null;

    final endpoint = _extractTagText(xml, 'Address');
    final scopesText = _extractTagText(xml, 'Scopes') ?? '';
    final typesText = _extractTagText(xml, 'Types') ?? '';

    final xaddrs = xaddrsText
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(Uri.tryParse)
        .whereType<Uri>()
        .toList();
    if (xaddrs.isEmpty) return null;

    final scopes = scopesText
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final types = typesText
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return OnvifDiscoveredDevice(
      endpointReference: endpoint?.trim().isEmpty == true ? null : endpoint?.trim(),
      xaddrs: xaddrs,
      scopes: scopes,
      types: types,
    );
  }

  static String? _tryParseSoapFault(String body) {
    final reason =
        _extractTagText(body, 'Text') ?? _extractTagText(body, 'Reason');
    if (reason != null && reason.trim().isNotEmpty) return reason.trim();
    final code = _extractTagText(body, 'Value') ?? _extractTagText(body, 'Code');
    if (code != null && code.trim().isNotEmpty) return code.trim();
    return null;
  }

  static Map<String, String>? _tryParseDeviceInformation(String body) {
    // Extract known fields. We don't require strict response wrapper tags.
    final map = <String, String>{};
    for (final k in const [
      'Manufacturer',
      'Model',
      'FirmwareVersion',
      'SerialNumber',
      'HardwareId',
    ]) {
      final v = _extractTagText(body, k);
      if (v != null && v.trim().isNotEmpty) map[k] = v.trim();
    }
    return map.isEmpty ? null : map;
  }

  static String? _extractTagText(String xml, String localName) {
    // Matches both <ns:Tag> and <Tag>, case-sensitive on tag name.
    final re = RegExp(
      '<(?:\\w+:)?$localName\\b[^>]*>([\\s\\S]*?)</(?:\\w+:)?$localName>',
      multiLine: true,
    );
    final m = re.firstMatch(xml);
    if (m == null) return null;
    final raw = m.group(1) ?? '';
    return raw
        .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _uuidLike() {
    final r = Random.secure();
    String hex(int bytes) {
      final b = List<int>.generate(bytes, (_) => r.nextInt(256));
      return b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    }

    // Not RFC4122 strict; good enough for MessageID uniqueness.
    return '${hex(4)}-${hex(2)}-${hex(2)}-${hex(2)}-${hex(6)}';
  }
}

