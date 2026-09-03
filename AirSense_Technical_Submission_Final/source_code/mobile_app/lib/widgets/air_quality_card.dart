import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class AirQualityCard extends StatelessWidget {
  final SensorData sensorData;

  const AirQualityCard({
    super.key,
    required this.sensorData,
  });

  Color _getCategoryColor(AirQualityCategory category) {
    switch (category) {
      case AirQualityCategory.good:
        return Colors.green;
      case AirQualityCategory.moderate:
        return const Color(0xFFFFB300); // Amber
      case AirQualityCategory.unhealthy:
        return Colors.orange;
      case AirQualityCategory.poor:
        return Colors.redAccent;
    }
  }

  String _getCategoryDescription(AirQualityCategory category) {
    switch (category) {
      case AirQualityCategory.good:
        return 'Air quality is satisfactory, and air pollution poses little or no risk.';
      case AirQualityCategory.moderate:
        return 'Air quality is acceptable. However, there may be a risk for some people.';
      case AirQualityCategory.unhealthy:
        return 'Members of sensitive groups may experience health effects. The general public is less likely to be affected.';
      case AirQualityCategory.poor:
        return 'Everyone may begin to experience health effects; members of sensitive groups may experience more serious health effects.';
    }
  }

  String _getCategoryTip(AirQualityCategory category) {
    switch (category) {
      case AirQualityCategory.good:
        return 'Perfect day for outdoor activities!';
      case AirQualityCategory.moderate:
        return 'Sensitive groups should limit prolonged outdoor activity.';
      case AirQualityCategory.unhealthy:
        return 'Consider reducing heavy outdoor work or exercise.';
      case AirQualityCategory.poor:
        return 'Avoid outdoor exertion. Wear masks and keep windows closed.';
    }
  }

  IconData _getCategoryIcon(AirQualityCategory category) {
    switch (category) {
      case AirQualityCategory.good:
        return Icons.sentiment_very_satisfied_rounded;
      case AirQualityCategory.moderate:
        return Icons.sentiment_satisfied_rounded;
      case AirQualityCategory.unhealthy:
        return Icons.sentiment_dissatisfied_rounded;
      case AirQualityCategory.poor:
        return Icons.sentiment_very_dissatisfied_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = sensorData.airQualityCategory;
    final mainColor = _getCategoryColor(category);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [mainColor.withOpacity(0.2), mainColor.withOpacity(0.05)]
              : [mainColor.withOpacity(0.12), mainColor.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: mainColor.withOpacity(isDark ? 0.3 : 0.2),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Air Quality',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: mainColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: isDark ? Colors.white : mainColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isDark ? Colors.white : mainColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCategoryDescription(category),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: mainColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getCategoryTip(category),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
