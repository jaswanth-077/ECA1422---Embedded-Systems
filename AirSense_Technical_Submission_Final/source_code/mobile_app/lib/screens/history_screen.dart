import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../repositories/sensor_repository.dart';
import '../widgets/trend_chart.dart';
import '../widgets/scatter_plot.dart';
import '../widgets/status_distribution_chart.dart';

class HistoryScreen extends StatefulWidget {
  final SensorRepository repository;

  const HistoryScreen({
    super.key,
    required this.repository,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SensorData>> _historicalDataFuture;
  int _selectedMetricIndex = 0; // 0 = PM2.5, 1 = Temperature, 2 = Humidity

  @override
  void initState() {
    super.initState();
    _historicalDataFuture = widget.repository.getHistoricalSensorData();
  }

  void _refresh() {
    setState(() {
      _historicalDataFuture = widget.repository.getHistoricalSensorData();
    });
  }

  // Statistics for selected time-series metric (Min, Avg, Max)
  Map<String, double> _calculateStats(List<SensorData> list) {
    if (list.isEmpty) return {'avg': 0, 'min': 0, 'max': 0};

    final List<double> values = list.map((d) {
      if (_selectedMetricIndex == 1) return d.temperature;
      if (_selectedMetricIndex == 2) return d.humidity;
      return d.pm25;
    }).toList();

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final avgVal = values.reduce((a, b) => a + b) / values.length;

    return {
      'avg': double.parse(avgVal.toStringAsFixed(1)),
      'min': minVal,
      'max': maxVal,
    };
  }

  // PM2.5 statistical calculations: Min, Avg, Max, Population Std Dev, Peak with timestamp
  Map<String, dynamic> _calculatePm25Stats(List<SensorData> list) {
    if (list.isEmpty) {
      return {
        'min': 0.0,
        'avg': 0.0,
        'max': 0.0,
        'stdDev': 0.0,
        'peak': 0.0,
        'peakTimestamp': null,
      };
    }

    final pmValues = list.map((d) => d.pm25).toList();
    final double minVal = pmValues.reduce((a, b) => a < b ? a : b);
    final double maxVal = pmValues.reduce((a, b) => a > b ? a : b);
    final double sum = pmValues.reduce((a, b) => a + b);
    final double mean = sum / pmValues.length;

    // Population standard deviation formula: sqrt(sum((x - mean)^2) / N)
    double varianceSum = 0.0;
    for (final x in pmValues) {
      varianceSum += (x - mean) * (x - mean);
    }
    final double stdDev = math.sqrt(varianceSum / pmValues.length);

    // Peak PM2.5 reading and its timestamp
    final SensorData peakReading = list.firstWhere(
      (d) => d.pm25 == maxVal,
      orElse: () => list.first,
    );

    return {
      'min': minVal,
      'avg': double.parse(mean.toStringAsFixed(1)),
      'max': maxVal,
      'stdDev': double.parse(stdDev.toStringAsFixed(2)),
      'peak': maxVal,
      'peakTimestamp': peakReading.timestamp,
    };
  }

  String _getMetricUnit() {
    if (_selectedMetricIndex == 1) return '°C';
    if (_selectedMetricIndex == 2) return '%';
    return 'µg/m³';
  }

  String _getMetricKey() {
    if (_selectedMetricIndex == 1) return 'temperature';
    if (_selectedMetricIndex == 2) return 'humidity';
    return 'pm25';
  }

  Color _getMetricColor() {
    if (_selectedMetricIndex == 1) return Colors.orange;
    if (_selectedMetricIndex == 2) return Colors.blue;
    return Colors.teal;
  }

  String _formatTimestamp(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

  String _formatFullTimestamp(DateTime? dt) {
    if (dt == null) return 'N/A';
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final metricColor = _getMetricColor();
    final unit = _getMetricUnit();

    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
      },
      child: FutureBuilder<List<SensorData>>(
        future: _historicalDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading history from Firebase',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? [];
          final stats = _calculateStats(data);
          final pm25Stats = _calculatePm25Stats(data);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Subtitle
                  Text(
                    'Historical Data',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Analyze logged sensor readings & correlation trends',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PM2.5 Simulation Disclaimer Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: isDark ? 0.35 : 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? Colors.amber[300] : Colors.amber[800],
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Development / Simulated Telemetry Notice',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.amber[300] : Colors.amber[900],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PM2.5 values are generated programmatically by ESP32 firmware simulation for algorithm testing while the optical dust sensor (GP2Y1014) is being calibrated.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Segmented metric switches
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[850]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildMetricTab(0, 'PM2.5', Colors.teal),
                        _buildMetricTab(1, 'Temp', Colors.orange),
                        _buildMetricTab(2, 'Humidity', Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Time-series Trend chart card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1.5,
                      ),
                    ),
                    child: TrendChart(
                      data: data,
                      metric: _getMetricKey(),
                      lineColor: metricColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row for selected time-series metric
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'MIN',
                          '${stats['min']}',
                          unit,
                          metricColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'AVERAGE',
                          '${stats['avg']}',
                          unit,
                          metricColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'MAX',
                          '${stats['max']}',
                          unit,
                          metricColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // PM2.5 Statistics Summary Card (Min, Avg, Max, Std Dev, Peak + timestamp)
                  _buildPm25StatsCard(context, pm25Stats, isDark),
                  const SizedBox(height: 28),

                  // Section Header: Project Analytical Visualizations
                  Text(
                    'Analytical Visualizations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Correlation scatter plots & air-quality status distribution',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. PM2.5 vs Temperature Scatter Plot Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.thermostat_rounded, color: Colors.orange, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PM2.5 vs Temperature',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'X: Temperature (°C)  •  Y: PM2.5 (µg/m³)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10.5,
                                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ScatterPlot(
                          data: data,
                          xMetric: 'temperature',
                          xLabel: 'Temperature (°C)',
                          pointColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. PM2.5 vs Humidity Scatter Plot Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.water_drop_rounded, color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PM2.5 vs Humidity',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'X: Humidity (%)  •  Y: PM2.5 (µg/m³)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10.5,
                                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ScatterPlot(
                          data: data,
                          xMetric: 'humidity',
                          xLabel: 'Humidity (%)',
                          pointColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Air-Quality Status Distribution Bar Chart Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.bar_chart_rounded, color: Colors.teal, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Air-Quality Status Distribution',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Categorical frequency breakdown from /readings',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10.5,
                                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        StatusDistributionChart(data: data),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Detailed Readings Log Section (Retained)
                  Text(
                    'Detailed Readings Log',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Log list
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDark ? Colors.grey[850]! : Colors.grey[100]!,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        // Display chronologically reversed (newest first)
                        final item = data[data.length - 1 - index];
                        double displayValue = item.pm25;
                        if (_selectedMetricIndex == 1) displayValue = item.temperature;
                        if (_selectedMetricIndex == 2) displayValue = item.humidity;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimestamp(item.timestamp),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '$displayValue',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    unit,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // PM2.5 Statistical Summary Card
  Widget _buildPm25StatsCard(
    BuildContext context,
    Map<String, dynamic> stats,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final peakTimestamp = stats['peakTimestamp'] as DateTime?;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PM2.5 Statistical Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Dynamic statistical dispersion from /readings',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4-grid stats
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  context,
                  'MINIMUM',
                  '${stats['min']}',
                  'µg/m³',
                  Colors.teal,
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat(
                  context,
                  'AVERAGE',
                  '${stats['avg']}',
                  'µg/m³',
                  Colors.teal,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  context,
                  'MAXIMUM',
                  '${stats['max']}',
                  'µg/m³',
                  Colors.teal,
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat(
                  context,
                  'STD DEV (σ)',
                  '±${stats['stdDev']}',
                  'µg/m³',
                  Colors.indigoAccent,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Peak PM2.5 highlight banner with timestamp
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.deepOrange.withValues(alpha: isDark ? 0.4 : 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.deepOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PEAK PM2.5 EVENT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${stats['peak']}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'µg/m³',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Recorded: ${_formatFullTimestamp(peakTimestamp)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTab(int index, String label, Color color) {
    final isSelected = _selectedMetricIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMetricIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? color.withValues(alpha: 0.2) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: isDark ? color : Colors.grey[300]!,
                    width: isDark ? 1.5 : 1,
                  )
                : null,
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? (isDark ? Colors.white : color)
                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
