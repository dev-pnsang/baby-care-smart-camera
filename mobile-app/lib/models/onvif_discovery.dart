class OnvifDiscoveredDevice {
  final String? endpointReference;
  final List<Uri> xaddrs;
  final List<String> scopes;
  final List<String> types;

  const OnvifDiscoveredDevice({
    required this.endpointReference,
    required this.xaddrs,
    required this.scopes,
    required this.types,
  });

  String? get primaryHost {
    if (xaddrs.isEmpty) return null;
    return xaddrs.first.host.isNotEmpty ? xaddrs.first.host : null;
  }
}

class OnvifConnectionTestResult {
  final OnvifDiscoveredDevice device;
  final Uri? deviceService;
  final bool ok;
  final int? httpStatus;
  final String? fault;
  final String? manufacturer;
  final String? model;
  final String? firmwareVersion;
  final String? serialNumber;
  final String? hardwareId;

  const OnvifConnectionTestResult({
    required this.device,
    required this.deviceService,
    required this.ok,
    required this.httpStatus,
    required this.fault,
    required this.manufacturer,
    required this.model,
    required this.firmwareVersion,
    required this.serialNumber,
    required this.hardwareId,
  });
}

