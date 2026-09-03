class DeviceInfo {
  final String name;
  final bool isOnline;
  final String wifiStatus; // e.g. 'Connected', 'Disconnected'
  final bool dht11Connected;
  final bool gp2y1014Connected;
  final String cloudStatus; // e.g. 'Not connected yet', 'Connected'
  final String firmwareVersion;

  DeviceInfo({
    required this.name,
    required this.isOnline,
    required this.wifiStatus,
    required this.dht11Connected,
    required this.gp2y1014Connected,
    required this.cloudStatus,
    required this.firmwareVersion,
  });
}
