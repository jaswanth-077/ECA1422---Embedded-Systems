import 'package:flutter/material.dart';
import '../models/device_info.dart';
import '../repositories/sensor_repository.dart';

class DeviceScreen extends StatelessWidget {
  final SensorRepository repository;

  const DeviceScreen({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<DeviceInfo>(
      stream: repository.getDeviceInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading device status: ${snapshot.error}'),
          );
        }

        final info = snapshot.data ??
            DeviceInfo(
              name: 'AirSense ESP32',
              isOnline: true,
              wifiStatus: 'Connected',
              dht11Connected: true,
              gp2y1014Connected: true,
              cloudStatus: 'Not connected yet',
              firmwareVersion: 'Development',
            );

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Status',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Hardware & connectivity diagnostics',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),

                // Microcontroller Visualization card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.blueGrey[800]!, Colors.blueGrey[900]!]
                          : [Colors.blueGrey[50]!, Colors.blueGrey[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.blueGrey[750]! : Colors.blueGrey[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.developer_board_rounded,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Firmware: ${info.firmwareVersion}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status categories
                _buildCategoryTitle(context, 'Connectivity'),
                const SizedBox(height: 8),
                _buildStatusGroup(
                  context: context,
                  isDark: isDark,
                  items: [
                    _buildStatusRow(
                      context: context,
                      icon: Icons.wifi_rounded,
                      label: 'Wi-Fi Status',
                      value: info.wifiStatus,
                      valueColor: info.wifiStatus == 'Connected' ? Colors.green : Colors.red,
                    ),
                    _buildStatusRow(
                      context: context,
                      icon: Icons.cloud_queue_rounded,
                      label: 'Cloud Sync',
                      value: info.cloudStatus,
                      // FUTURE FIREBASE INTEGRATION:
                      // Once Firebase Realtime Database is implemented, the repository stream will yield
                      // a DeviceInfo with cloudStatus: 'Connected' (or 'Disconnected') rather than 'Not connected yet'.
                      // The UI will dynamically update and change the status text and color accordingly.
                      valueColor: info.cloudStatus == 'Connected'
                          ? Colors.green
                          : (info.cloudStatus == 'Not connected yet'
                              ? Colors.orange
                              : Colors.red),
                    ),
                    _buildStatusRow(
                      context: context,
                      icon: Icons.circle_notifications_rounded,
                      label: 'System Status',
                      value: info.isOnline ? 'Online' : 'Offline',
                      valueColor: info.isOnline ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildCategoryTitle(context, 'Sensor Hardware Diagnostics'),
                const SizedBox(height: 8),
                _buildStatusGroup(
                  context: context,
                  isDark: isDark,
                  items: [
                    _buildStatusRow(
                      context: context,
                      icon: Icons.thermostat_rounded,
                      label: 'DHT11 (Temp/Hum)',
                      value: info.dht11Connected ? 'Connected' : 'Disconnected',
                      valueColor: info.dht11Connected ? Colors.green : Colors.red,
                    ),
                    _buildStatusRow(
                      context: context,
                      icon: Icons.blur_on_rounded,
                      label: 'GP2Y1014 (PM2.5)',
                      value: info.gp2y1014Connected ? 'Connected' : 'Disconnected',
                      valueColor: info.gp2y1014Connected ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.5,
          ),
    );
  }

  Widget _buildStatusGroup({
    required BuildContext context,
    required bool isDark,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Divider(
              color: isDark ? Colors.grey[850]! : Colors.grey[100]!,
              height: 1,
            );
          }
          return items[index ~/ 2];
        }),
      ),
    );
  }

  Widget _buildStatusRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
