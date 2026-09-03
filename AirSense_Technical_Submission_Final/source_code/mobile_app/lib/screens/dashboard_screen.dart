import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../models/device_info.dart';
import '../repositories/sensor_repository.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/sensor_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/device_status_section.dart';

class DashboardScreen extends StatefulWidget {
  final SensorRepository repository;

  const DashboardScreen({
    super.key,
    required this.repository,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<SensorData> _liveDataStream;
  late Stream<DeviceInfo> _deviceInfoStream;
  late Future<List<SensorData>> _historicalDataFuture;

  @override
  void initState() {
    super.initState();
    _liveDataStream = widget.repository.getLiveSensorData();
    _deviceInfoStream = widget.repository.getDeviceInfo();
    _historicalDataFuture = widget.repository.getHistoricalSensorData();
  }

  void _refreshHistoricalData() {
    setState(() {
      _historicalDataFuture = widget.repository.getHistoricalSensorData();
    });
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<SensorData>(
      stream: _liveDataStream,
      builder: (context, liveSnapshot) {
        if (liveSnapshot.hasError) {
          return Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Connection Offline',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to retrieve live telemetry from the cloud database.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        liveSnapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _liveDataStream = widget.repository.getLiveSensorData();
                          _deviceInfoStream = widget.repository.getDeviceInfo();
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry Connection'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (liveSnapshot.connectionState == ConnectionState.waiting && !liveSnapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Connecting to AirSense Cloud...',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        // Fallback baseline data if stream hasn't emitted yet
        final liveData = liveSnapshot.data ??
            SensorData(
              temperature: 30.3,
              humidity: 74.8,
              pm25: 18.6,
              timestamp: DateTime.now(),
            );

        return StreamBuilder<DeviceInfo>(
          stream: _deviceInfoStream,
          builder: (context, deviceSnapshot) {
            final deviceInfo = deviceSnapshot.data ??
                DeviceInfo(
                  name: 'AirSense ESP32',
                  isOnline: true,
                  wifiStatus: 'Connected',
                  dht11Connected: true,
                  gp2y1014Connected: true,
                  cloudStatus: 'Not connected yet',
                  firmwareVersion: 'Development',
                );

            return RefreshIndicator(
              onRefresh: () async {
                _refreshHistoricalData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Connection Status pill and Title Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AirSense',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                'Live Air Quality Monitoring',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: deviceInfo.isOnline
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: deviceInfo.isOnline ? Colors.green : Colors.redAccent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: deviceInfo.isOnline ? Colors.green : Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  deviceInfo.isOnline ? 'Device Online' : 'Device Offline',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: deviceInfo.isOnline
                                        ? (isDark ? Colors.green[300] : Colors.green[800])
                                        : (isDark ? Colors.red[300] : Colors.red[800]),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Overall Air Quality Card
                      AirQualityCard(sensorData: liveData),
                      const SizedBox(height: 20),

                      // Sensor Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          SensorCard(
                            title: 'Temperature',
                            value: liveData.temperature.toStringAsFixed(1),
                            unit: '°C',
                            icon: Icons.thermostat_rounded,
                            color: Colors.orange,
                          ),
                          SensorCard(
                            title: 'Humidity',
                            value: liveData.humidity.toStringAsFixed(1),
                            unit: '%',
                            icon: Icons.water_drop_rounded,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Full width PM2.5 Card
                      SensorCard(
                        title: 'PM2.5 Concentration',
                        value: liveData.pm25.toStringAsFixed(1),
                        unit: 'µg/m³',
                        icon: Icons.blur_on_rounded,
                        color: Colors.teal,
                        subtitle: 'Optical Dust Sensor',
                      ),
                      
                      const SizedBox(height: 12),
                      // Last Updated timestamp
                      Center(
                        child: Text(
                          'Last updated: ${_formatTimestamp(liveData.timestamp)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Trend Chart Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's PM2.5 Trend",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Last 10 readings',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                            width: 1.5,
                          ),
                        ),
                        child: FutureBuilder<List<SensorData>>(
                          future: _historicalDataFuture,
                          builder: (context, histSnapshot) {
                            if (histSnapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 200,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (histSnapshot.hasError) {
                              return SizedBox(
                                height: 200,
                                child: Center(
                                  child: Text('Error loading chart: ${histSnapshot.error}'),
                                ),
                              );
                            }
                            final list = histSnapshot.data ?? [];
                            return TrendChart(
                              data: list,
                              metric: 'pm25',
                              lineColor: Colors.teal,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Device Diagnostic Status
                      DeviceStatusSection(deviceInfo: deviceInfo),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
