import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class ScatterPlot extends StatelessWidget {
  final List<SensorData> data;
  final String xMetric; // 'temperature' or 'humidity'
  final String xLabel;
  final String yLabel;
  final Color pointColor;

  const ScatterPlot({
    super.key,
    required this.data,
    required this.xMetric,
    required this.xLabel,
    this.yLabel = 'PM2.5 (µg/m³)',
    required this.pointColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.isEmpty) {
      return const SizedBox(
        height: 190,
        child: Center(
          child: Text('No historical data available for scatter plot.'),
        ),
      );
    }

    final points = <_DataPoint>[];
    for (final d in data) {
      final double xVal = (xMetric == 'temperature') ? d.temperature : d.humidity;
      final double yVal = d.pm25;
      points.add(_DataPoint(x: xVal, y: yVal, category: d.airQualityCategory));
    }

    // Calculate correlation coefficient (Pearson r)
    final double? r = _calculatePearsonR(points);

    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 10, right: 14),
      height: 220,
      width: double.infinity,
      child: Column(
        children: [
          // Header showing point count and Pearson correlation r
          Padding(
            padding: const EdgeInsets.only(left: 36, right: 8, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${points.length} data points',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (r != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pointColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Pearson r = ${r.toStringAsFixed(2)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: pointColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ScatterPlotPainter(
                points: points,
                xLabel: xLabel,
                yLabel: yLabel,
                defaultColor: pointColor,
                textColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ?? Colors.grey,
                gridColor: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                axisColor: isDark ? Colors.grey[700]! : Colors.grey[400]!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double? _calculatePearsonR(List<_DataPoint> pts) {
    if (pts.length < 2) return null;
    double sumX = 0, sumY = 0;
    for (final p in pts) {
      sumX += p.x;
      sumY += p.y;
    }
    final int n = pts.length;
    final double meanX = sumX / n;
    final double meanY = sumY / n;

    double num = 0, denX = 0, denY = 0;
    for (final p in pts) {
      final double dx = p.x - meanX;
      final double dy = p.y - meanY;
      num += dx * dy;
      denX += dx * dx;
      denY += dy * dy;
    }
    if (denX == 0 || denY == 0) return 0.0;
    return num / math.sqrt(denX * denY);
  }
}

class _DataPoint {
  final double x;
  final double y;
  final AirQualityCategory category;

  _DataPoint({required this.x, required this.y, required this.category});
}

class _ScatterPlotPainter extends CustomPainter {
  final List<_DataPoint> points;
  final String xLabel;
  final String yLabel;
  final Color defaultColor;
  final Color textColor;
  final Color gridColor;
  final Color axisColor;

  _ScatterPlotPainter({
    required this.points,
    required this.xLabel,
    required this.yLabel,
    required this.defaultColor,
    required this.textColor,
    required this.gridColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 38.0;
    const double paddingBottom = 26.0;
    const double paddingTop = 8.0;
    const double paddingRight = 10.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingBottom - paddingTop;

    if (points.isEmpty || chartWidth <= 0 || chartHeight <= 0) return;

    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;

    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    // Add padding margin to ranges
    if (minX == maxX) {
      minX -= 1.0;
      maxX += 1.0;
    } else {
      final span = maxX - minX;
      minX -= span * 0.1;
      maxX += span * 0.1;
    }

    if (minY == maxY) {
      minY -= 1.0;
      maxY += 1.0;
    } else {
      final span = maxY - minY;
      minY -= span * 0.1;
      maxY += span * 0.1;
    }

    // Grid paint
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    // Draw horizontal gridlines & Y labels (3 intervals)
    const int yDivisions = 3;
    for (int i = 0; i <= yDivisions; i++) {
      final double fraction = i / yDivisions;
      final double y = paddingTop + chartHeight - (fraction * chartHeight);
      final double val = minY + (fraction * (maxY - minY));

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final textSpan = TextSpan(
        text: val.toStringAsFixed(1),
        style: textStyle,
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 4, y - tp.height / 2));
    }

    // Draw vertical gridlines & X labels (3 intervals)
    const int xDivisions = 3;
    for (int i = 0; i <= xDivisions; i++) {
      final double fraction = i / xDivisions;
      final double x = paddingLeft + (fraction * chartWidth);
      final double val = minX + (fraction * (maxX - minX));

      canvas.drawLine(
        Offset(x, paddingTop),
        Offset(x, paddingTop + chartHeight),
        gridPaint,
      );

      final textSpan = TextSpan(
        text: val.toStringAsFixed(1),
        style: textStyle,
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, paddingTop + chartHeight + 4));
    }

    // Draw main axes
    canvas.drawLine(
      Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, paddingTop + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(paddingLeft, paddingTop + chartHeight),
      Offset(size.width - paddingRight, paddingTop + chartHeight),
      axisPaint,
    );

    // Axis titles
    final xLabelSpan = TextSpan(
      text: xLabel,
      style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 9.5),
    );
    final xTp = TextPainter(text: xLabelSpan, textDirection: TextDirection.ltr);
    xTp.layout();
    xTp.paint(
      canvas,
      Offset(paddingLeft + (chartWidth - xTp.width) / 2, size.height - xTp.height),
    );

    // Plot scatter dots
    for (final p in points) {
      final double normX = (p.x - minX) / (maxX - minX);
      final double normY = (p.y - minY) / (maxY - minY);

      final double cx = paddingLeft + (normX * chartWidth);
      final double cy = paddingTop + chartHeight - (normY * chartHeight);

      // Color point based on AirQualityCategory for rich visual correlation
      Color dotColor;
      switch (p.category) {
        case AirQualityCategory.good:
          dotColor = Colors.green;
          break;
        case AirQualityCategory.moderate:
          dotColor = Colors.amber[700] ?? Colors.orange;
          break;
        case AirQualityCategory.unhealthy:
          dotColor = Colors.deepOrange;
          break;
        case AirQualityCategory.poor:
          dotColor = Colors.purple;
          break;
      }

      // Outer glow/fill
      final fillPaint = Paint()
        ..color = dotColor.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 4.5, fillPaint);

      // Border ring
      final strokePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(cx, cy), 4.5, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterPlotPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.xLabel != xLabel ||
        oldDelegate.yLabel != yLabel ||
        oldDelegate.defaultColor != defaultColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor;
  }
}
