import 'package:flutter/material.dart';

import '../models/onvif_discovery.dart';
import '../services/onvif_discovery_service.dart';
import '../theme/design_tokens.dart';

class _OnvifTestCache {
  OnvifConnectionTestResult? result;
  bool loading = false;
}

class OnvifScanSheet extends StatefulWidget {
  final List<OnvifDiscoveredDevice> devices;
  final String username;
  final String password;
  final Future<void> Function(String ip) onPickIp;

  const OnvifScanSheet({
    super.key,
    required this.devices,
    required this.username,
    required this.password,
    required this.onPickIp,
  });

  @override
  State<OnvifScanSheet> createState() => _OnvifScanSheetState();
}

class _OnvifScanSheetState extends State<OnvifScanSheet> {
  final _service = OnvifDiscoveryService();
  final Map<String, _OnvifTestCache> _cache = {};

  _OnvifTestCache _entryFor(OnvifDiscoveredDevice d) {
    final key = d.endpointReference ??
        (d.xaddrs.isNotEmpty ? d.xaddrs.first.toString() : d.hashCode.toString());
    return _cache.putIfAbsent(key, () => _OnvifTestCache());
  }

  Future<void> _ensureTest(OnvifDiscoveredDevice d) async {
    final entry = _entryFor(d);
    if (entry.loading || entry.result != null) return;
    setState(() => entry.loading = true);
    try {
      final r = await _service.testConnection(
        device: d,
        username: widget.username,
        password: widget.password,
      );
      if (!mounted) return;
      setState(() => entry.result = r);
    } finally {
      if (mounted) setState(() => entry.loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = widget.devices;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Thiết bị ONVIF tìm được',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (devices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Không tìm thấy camera ONVIF trong mạng.\n'
                'Gợi ý: đảm bảo điện thoại và camera cùng Wi‑Fi, và Wi‑Fi cho phép multicast.',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final d = devices[i];
                  final entry = _entryFor(d);

                  // Start test when item becomes visible.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _ensureTest(d);
                  });

                  final host = d.primaryHost ?? '(unknown)';
                  final title = host;
                  final subtitle = d.scopes.isNotEmpty
                      ? d.scopes.take(2).join('\n')
                      : (d.xaddrs.isNotEmpty ? d.xaddrs.first.toString() : '');

                  Color chipColor;
                  String chipText;
                  if (entry.loading) {
                    chipColor = DesignTokens.warning6;
                    chipText = 'Đang test...';
                  } else if (entry.result == null) {
                    chipColor = DesignTokens.warning6;
                    chipText = 'Chờ';
                  } else if (entry.result!.ok) {
                    chipColor = DesignTokens.success6;
                    chipText = 'OK';
                  } else {
                    chipColor = DesignTokens.error6;
                    chipText = 'FAIL';
                  }

                  final info = entry.result;
                  final infoLine = info?.ok == true
                      ? [
                          info?.manufacturer,
                          info?.model,
                          info?.serialNumber,
                        ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' • ')
                      : (info?.fault ?? '');

                  return InkWell(
                    onTap: (d.primaryHost == null)
                        ? null
                        : () async => widget.onPickIp(d.primaryHost!),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: DesignTokens.neutral12.withOpacity(0.12),
                        ),
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: chipColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: chipColor),
                                ),
                                child: Text(
                                  chipText,
                                  style: TextStyle(
                                    color: chipColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: DesignTokens.neutral12.withOpacity(0.65),
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                          if (infoLine.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              infoLine,
                              style: TextStyle(
                                color: info?.ok == true
                                    ? DesignTokens.success6
                                    : DesignTokens.error6,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

