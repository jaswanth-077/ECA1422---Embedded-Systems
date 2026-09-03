import '../models/sensor_data.dart';
import '../models/device_info.dart';

abstract class SensorRepository {
  /// Stream of live sensor data readings.
  Stream<SensorData> getLiveSensorData();

  /// Historical sensor data readings for charts.
  Future<List<SensorData>> getHistoricalSensorData();

  /// Stream of current device information and connection statuses.
  Stream<DeviceInfo> getDeviceInfo();
}
