import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/sensor_data.dart';

class TrendChart extends StatelessWidget {
  final List<SensorData> data;
  final String metric; // 'pm25', 'temperature', 'humidity'
  final Color lineColor;

  const TrendChart({
    super.key,
    required this.data,
    required this.metric,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No historical data available.')),
      );
    }

    final List<double> values = data.map((d) {
      switch (metric) {
        case 'temperature':
          return d.temperature;
        case 'humidity':
          return d.humidity;
        case 'pm25':
        default:
          return d.pm25;
      }
    }).toList();

    final List<String> labels = data.map((d) {
      // Just return HH:mm format for timestamps
      return '${d.timestamp.hour.toString().padLeft(2, '0')}:${d.timestamp.minute.toString().padLeft(2, '0')}';
    }).toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8, right: 16),
      height: 200,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(
          values: values,
          labels: labels,
          lineColor: lineColor,
          textColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey,
          gridColor: isDark ? Colors.grey[850]! : Colors.grey[200]!,
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final Color textColor;
  final Color gridColor;

  _LineChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 32.0;
    const double paddingBottom = 20.0;
    
    final double chartWidth = size.width - paddingLeft;
    final double chartHeight = size.height - paddingBottom;

    if (values.isEmpty) return;

    // Find min/max values for scaling, add padding so the line doesn't touch the top/bottom edges
    double minVal = values.reduce((a, b) => a < b ? a : b);
    double maxVal = values.reduce((a, b) => a > b ? a : b);
    
    if (minVal == maxVal) {
      minVal -= 1.0;
      maxVal += 1.0;
    } else {
      final range = maxVal - minVal;
      minVal -= range * 0.15;
      maxVal += range * 0.15;
    }

    // Grid details
    final int gridLinesCount = 3;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Draw Y-axis grid lines and labels
    for (int i = 0; i <= gridLinesCount; i++) {
      final double fraction = i / gridLinesCount;
      final double y = chartHeight - (fraction * chartHeight);
      final double value = minVal + (fraction * (maxVal - minVal));

      // Draw grid line
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Draw text label for Y axis
      final textSpan = TextSpan(
        text: value.toStringAsFixed(1),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Coordinates points
    final List<Offset> points = [];
    final double stepX = values.length > 1 ? chartWidth / (values.length - 1) : chartWidth;

    for (int i = 0; i < values.length; i++) {
      final double x = paddingLeft + (i * stepX);
      final double normalizedY = (values[i] - minVal) / (maxVal - minVal);
      final double y = chartHeight - (normalizedY * chartHeight);
      points.add(Offset(x, y));

      // Draw X-axis timestamps for occasional indices to prevent crowding
      if (i % 2 == 0 || i == values.length - 1) {
        final textSpan = TextSpan(
          text: labels[i],
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartHeight + 6),
        );
      }
    }

    // Draw Line and Gradient Fill
    if (points.isNotEmpty) {
      final Path linePath = Path();
      linePath.moveTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        // Use smooth bezier curves or clean lines. Standard line is clean and precise.
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      // Draw gradient under line
      final Path fillPath = Path.from(linePath);
      fillPath.lineTo(points.last.dx, chartHeight);
      fillPath.lineTo(points.first.dx, chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, chartHeight),
          [
            lineColor.withOpacity(0.3),
            lineColor.withOpacity(0.0),
          ],
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      // Draw the line itself
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, linePaint);

      // Draw highlight dots on points
      final dotOuterPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final dotInnerPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 5.0, dotInnerPaint);
        canvas.drawCircle(point, 3.0, dotOuterPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor;
  }
}
