import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:air_sense/main.dart';
import 'package:air_sense/models/sensor_data.dart';
import 'package:air_sense/models/device_info.dart';
import 'package:air_sense/repositories/sensor_repository.dart';
import 'package:air_sense/widgets/scatter_plot.dart';
import 'package:air_sense/widgets/status_distribution_chart.dart';

/// A clean repository implementation for testing that avoids periodic timers.
class TestSensorRepository implements SensorRepository {
  final List<SensorData> historicalData;

  TestSensorRepository({List<SensorData>? history})
      : historicalData = history ??
            [
              SensorData(
                temperature: 24.5,
                humidity: 50.0,
                pm25: 10.0, // GOOD
                timestamp: DateTime(2026, 9, 2, 9, 0, 0),
                status: 'GOOD',
              ),
              SensorData(
                temperature: 25.0,
                humidity: 52.0,
                pm25: 20.0, // MODERATE
                timestamp: DateTime(2026, 9, 2, 9, 10, 0),
                status: 'MODERATE',
              ),
              SensorData(
                temperature: 26.0,
                humidity: 55.0,
                pm25: 30.0, // MODERATE
                timestamp: DateTime(2026, 9, 2, 9, 20, 0),
                status: 'MODERATE',
              ),
              SensorData(
                temperature: 27.0,
                humidity: 60.0,
                pm25: 45.0, // UNHEALTHY
                timestamp: DateTime(2026, 9, 2, 9, 30, 0),
                status: 'UNHEALTHY',
              ),
              SensorData(
                temperature: 28.0,
                humidity: 65.0,
                pm25: 60.0, // POOR (Peak)
                timestamp: DateTime(2026, 9, 2, 9, 40, 0),
                status: 'POOR',
              ),
            ];

  @override
  Stream<SensorData> getLiveSensorData() {
    return Stream.value(
      SensorData(
        temperature: 25.6,
        humidity: 50.2,
        pm25: 22.5,
        timestamp: DateTime.now(),
        status: 'MODERATE',
      ),
    );
  }

  @override
  Future<List<SensorData>> getHistoricalSensorData() async {
    return historicalData;
  }

  @override
  Stream<DeviceInfo> getDeviceInfo() {
    return Stream.value(
      DeviceInfo(
        name: 'AirSense ESP32 Test',
        isOnline: true,
        wifiStatus: 'Connected',
        dht11Connected: true,
        gp2y1014Connected: true,
        cloudStatus: 'Connected',
        firmwareVersion: 'Test',
      ),
    );
  }
}

void main() {
  testWidgets('AirSense App renders correctly and contains title', (WidgetTester tester) async {
    final repository = TestSensorRepository();
    await tester.pumpWidget(AirSenseApp(repository: repository));
    await tester.pump();

    expect(find.text('AirSense'), findsWidgets);
  });

  test('Population standard deviation and PM2.5 stats calculate accurately', () {
    final data = [
      SensorData(
        temperature: 25.0,
        humidity: 50.0,
        pm25: 10.0,
        timestamp: DateTime(2026, 9, 2, 9, 0, 0),
      ),
      SensorData(
        temperature: 25.5,
        humidity: 51.0,
        pm25: 20.0,
        timestamp: DateTime(2026, 9, 2, 9, 10, 0),
      ),
      SensorData(
        temperature: 26.0,
        humidity: 52.0,
        pm25: 30.0,
        timestamp: DateTime(2026, 9, 2, 9, 20, 0),
      ),
    ];

    final pmValues = data.map((d) => d.pm25).toList();
    final double minVal = pmValues.reduce((a, b) => a < b ? a : b);
    final double maxVal = pmValues.reduce((a, b) => a > b ? a : b);
    final double sum = pmValues.reduce((a, b) => a + b);
    final double mean = sum / pmValues.length;

    // Population std dev: sqrt(sum((x - mean)^2) / N)
    double varianceSum = 0.0;
    for (final x in pmValues) {
      varianceSum += (x - mean) * (x - mean);
    }
    final double stdDev = math.sqrt(varianceSum / pmValues.length);

    expect(minVal, 10.0);
    expect(mean, 20.0);
    expect(maxVal, 30.0);
    expect(double.parse(stdDev.toStringAsFixed(2)), 8.16);
  });

  testWidgets('History screen displays analytical visualizations, stats, and simulation banner',
      (WidgetTester tester) async {
    final repository = TestSensorRepository();
    await tester.pumpWidget(AirSenseApp(repository: repository));
    await tester.pumpAndSettle();

    // Tap the History tab in bottom navigation
    final historyTab = find.text('History');
    expect(historyTab, findsOneWidget);
    await tester.tap(historyTab);
    await tester.pumpAndSettle();

    // Verify Title and Simulation Notice
    expect(find.text('Historical Data'), findsOneWidget);
    expect(find.textContaining('Development / Simulated Telemetry Notice'), findsOneWidget);

    // Verify PM2.5 Statistical Summary
    expect(find.text('PM2.5 Statistical Summary'), findsOneWidget);
    expect(find.text('STD DEV (σ)'), findsOneWidget);
    expect(find.text('PEAK PM2.5 EVENT'), findsOneWidget);

    // Verify Analytical Visualizations section and titles
    expect(find.text('Analytical Visualizations'), findsOneWidget);
    expect(find.text('PM2.5 vs Temperature'), findsOneWidget);
    expect(find.text('PM2.5 vs Humidity'), findsOneWidget);
    expect(find.text('Air-Quality Status Distribution'), findsOneWidget);

    // Verify widgets exist
    expect(find.byType(ScatterPlot), findsNWidgets(2));
    expect(find.byType(StatusDistributionChart), findsOneWidget);
  });
}
