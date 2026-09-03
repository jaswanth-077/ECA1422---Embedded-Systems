enum AirQualityCategory {
  good('GOOD'),
  moderate('MODERATE'),
  unhealthy('UNHEALTHY'),
  poor('POOR');

  final String label;
  const AirQualityCategory(this.label);
}

class SensorData {
  final double temperature;
  final double humidity;
  final double pm25;
  final DateTime timestamp;
  final String? status;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.pm25,
    required this.timestamp,
    this.status,
  });

  /// Dynamically calculates the air quality category based on PM2.5 concentration.
  AirQualityCategory get airQualityCategory {
    if (pm25 <= 12.0) {
      return AirQualityCategory.good;
    } else if (pm25 <= 35.4) {
      return AirQualityCategory.moderate;
    } else if (pm25 <= 55.4) {
      return AirQualityCategory.unhealthy;
    } else {
      return AirQualityCategory.poor;
    }
  }
}
