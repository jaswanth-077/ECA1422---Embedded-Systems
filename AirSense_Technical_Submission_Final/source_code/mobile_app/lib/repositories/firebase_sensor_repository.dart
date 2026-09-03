import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../models/device_info.dart';
import 'sensor_repository.dart';

class FirebaseSensorRepository implements SensorRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  Stream<SensorData> getLiveSensorData() {
    // Listen to changes at the "/sensor" node in real time.
    return _database.ref('sensor').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Sensor node does not exist in database.');
      }

      final dynamic value = snapshot.value;
      if (value is! Map) {
        throw Exception('Invalid data structure inside /sensor node.');
      }

      final dataMap = Map<dynamic, dynamic>.from(value);
      
      final tempVal = dataMap['temperature'];
      final humVal = dataMap['humidity'];
      final pm25Val = dataMap['pm25'];

      if (tempVal == null || humVal == null || pm25Val == null) {
        throw Exception('Missing required sensor readings in Firebase.');
      }

      final double? temp = (tempVal is num) ? tempVal.toDouble() : double.tryParse(tempVal.toString());
      final double? hum = (humVal is num) ? humVal.toDouble() : double.tryParse(humVal.toString());
      final double? pm25 = (pm25Val is num) ? pm25Val.toDouble() : double.tryParse(pm25Val.toString());

      if (temp == null || hum == null || pm25 == null) {
        throw Exception('Sensor readings could not be parsed as numbers.');
      }

      return SensorData(
        temperature: temp,
        humidity: hum,
        pm25: pm25,
        timestamp: DateTime.now(),
      );
    });
  }

  @override
  Future<List<SensorData>> getHistoricalSensorData() async {
    final snapshot = await _database.ref('readings').get();
    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final dynamic rawValue = snapshot.value;
    final List<SensorData> readings = [];

    DateTime? parsePushId(String id) {
      const pushChars = '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
      if (id.length < 8) return null;
      int time = 0;
      for (int i = 0; i < 8; i++) {
        final c = id[i];
        final index = pushChars.indexOf(c);
        if (index == -1) return null;
        time = time * 64 + index;
      }
      return DateTime.fromMillisecondsSinceEpoch(time);
    }

    void parseReading(String? key, dynamic val) {
      if (val is! Map) return;
      final map = Map<dynamic, dynamic>.from(val);

      final tempVal = map['temperature'];
      final humVal = map['humidity'];
      final pm25Val = map['pm25'];
      final timeVal = map['timestamp'];
      final statusVal = map['status']?.toString();

      final double? temp = (tempVal is num)
          ? tempVal.toDouble()
          : double.tryParse(tempVal?.toString() ?? '');
      final double? hum = (humVal is num)
          ? humVal.toDouble()
          : double.tryParse(humVal?.toString() ?? '');
      final double? pm25 = (pm25Val is num)
          ? pm25Val.toDouble()
          : double.tryParse(pm25Val?.toString() ?? '');

      DateTime? timestamp;
      if (timeVal is String) {
        timestamp = DateTime.tryParse(timeVal.replaceAll(' ', 'T')) ??
            DateTime.tryParse(timeVal);
      } else if (timeVal is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(timeVal);
      }

      // If timestamp field was not present in the record, decode it from Firebase push ID key
      if (timestamp == null && key != null) {
        timestamp = parsePushId(key);
      }
      timestamp ??= DateTime.now();

      if (temp != null && hum != null && pm25 != null) {
        readings.add(
          SensorData(
            temperature: temp,
            humidity: hum,
            pm25: pm25,
            timestamp: timestamp,
            status: statusVal,
          ),
        );
      }
    }

    if (rawValue is Map) {
      rawValue.forEach((key, val) => parseReading(key.toString(), val));
    } else if (rawValue is List) {
      for (final val in rawValue) {
        parseReading(null, val);
      }
    }

    // Sort chronologically ascending
    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return readings;
  }

  @override
  Stream<DeviceInfo> getDeviceInfo() {
    // Listen to Firebase RTDB special connection state tracker: .info/connected
    return _database.ref('.info/connected').onValue.map((event) {
      final isDbConnected = (event.snapshot.value as bool?) ?? false;

      return DeviceInfo(
        name: 'AirSense ESP32',
        isOnline: true, // Assuming online for diagnostics UI
        wifiStatus: 'Connected',
        dht11Connected: true,
        gp2y1014Connected: true, // Detected, but PM2.5 temporarily mocked on the physical hardware
        cloudStatus: isDbConnected ? 'Connected' : 'Connecting...',
        firmwareVersion: 'Development',
      );
    });
  }
}
