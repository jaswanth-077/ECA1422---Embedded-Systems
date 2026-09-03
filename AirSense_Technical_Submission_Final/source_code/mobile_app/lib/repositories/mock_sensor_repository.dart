import 'dart:async';
import 'dart:math' as math;
import '../models/sensor_data.dart';
import '../models/device_info.dart';
import 'sensor_repository.dart';

/// A mock repository that simulates a live ESP32 air-quality monitor
/// and provides stable, realistic initial and historical sensor values.
class MockSensorRepository implements SensorRepository {
  final _random = math.Random();

  // Baseline values
  double _currentTemp = 30.3;
  double _currentHumidity = 74.8;
  double _currentPm25 = 18.6;

  /// Returns a stream of live sensor readings.
  /// Simulates slight environmental fluctuations over time.
  @override
  Stream<SensorData> getLiveSensorData() {
    return Stream.periodic(const Duration(seconds: 4), (_) {
      // Apply very minor, realistic gradual fluctuations (e.g. natural room changes)
      // keeping values close to their baselines.
      _currentTemp += (_random.nextDouble() * 0.1 - 0.05); // +/- 0.05 °C
      _currentHumidity += (_random.nextDouble() * 0.2 - 0.1); // +/- 0.1 %
      _currentPm25 += (_random.nextDouble() * 0.2 - 0.1); // +/- 0.1 µg/m³

      // Bound values to realistic ranges
      _currentTemp = double.parse(_currentTemp.clamp(28.0, 32.0).toStringAsFixed(1));
      _currentHumidity = double.parse(_currentHumidity.clamp(65.0, 80.0).toStringAsFixed(1));
      _currentPm25 = double.parse(_currentPm25.clamp(14.0, 22.0).toStringAsFixed(1));

      return SensorData(
        temperature: _currentTemp,
        humidity: _currentHumidity,
        pm25: _currentPm25,
        timestamp: DateTime.now(),
      );
    });
  }

  /// Returns approximately the last 10 PM2.5 readings.
  /// Using the specific realistic values requested:
  /// 15.8, 16.4, 17.1, 16.8, 17.6, 18.1, 18.4, 18.0, 18.6, 18.6
  @override
  Future<List<SensorData>> getHistoricalSensorData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final pm25Readings = [15.8, 16.4, 17.1, 16.8, 17.6, 18.1, 18.4, 18.0, 18.6, 18.6];
    
    // Coinciding gradual temperature and humidity readings
    final tempReadings = [29.8, 29.9, 30.0, 30.1, 30.1, 30.2, 30.2, 30.3, 30.3, 30.3];
    final humidityReadings = [73.5, 73.8, 74.0, 74.2, 74.3, 74.5, 74.6, 74.7, 74.8, 74.8];

    return List.generate(pm25Readings.length, (index) {
      // Historical intervals of 10 minutes
      final timestamp = now.subtract(Duration(minutes: (pm25Readings.length - 1 - index) * 10));
      return SensorData(
        temperature: tempReadings[index],
        humidity: humidityReadings[index],
        pm25: pm25Readings[index],
        timestamp: timestamp,
      );
    });
  }

  /// Returns a stream of device information.
  /// In a production repository, this will listen to Firebase database connection state.
  @override
  Stream<DeviceInfo> getDeviceInfo() {
    // Yield device info immediately, and re-emit if status changes.
    // Since this is mock data, we yield a single persistent connection status.
    return Stream.value(
      DeviceInfo(
        name: 'AirSense ESP32',
        isOnline: true,
        wifiStatus: 'Connected',
        dht11Connected: true,
        gp2y1014Connected: true,
        cloudStatus: 'Not connected yet', // Dynamic UI field to be wired to Firebase later
        firmwareVersion: 'Development',
      ),
    );
  }
}
