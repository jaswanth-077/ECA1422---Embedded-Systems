import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class StatusDistributionChart extends StatelessWidget {
  final List<SensorData> data;

  const StatusDistributionChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    int goodCount = 0;
    int moderateCount = 0;
    int unhealthyCount = 0;
    int poorCount = 0;

    for (final d in data) {
      final status = (d.status ?? d.airQualityCategory.label).toUpperCase().trim();
      if (status == 'GOOD') {
        goodCount++;
      } else if (status == 'MODERATE') {
        moderateCount++;
      } else if (status == 'UNHEALTHY') {
        unhealthyCount++;
      } else if (status == 'POOR') {
        poorCount++;
      } else {
        // Fallback to PM2.5 standard category definition
        if (d.pm25 <= 12.0) {
          goodCount++;
        } else if (d.pm25 <= 35.4) {
          moderateCount++;
        } else if (d.pm25 <= 55.4) {
          unhealthyCount++;
        } else {
          poorCount++;
        }
      }
    }

    final int total = data.length;
    final categories = [
      _CategoryData(
        label: 'GOOD',
        threshold: '≤ 12 µg/m³',
        count: goodCount,
        color: Colors.green,
        percentage: total > 0 ? (goodCount / total * 100) : 0,
      ),
      _CategoryData(
        label: 'MODERATE',
        threshold: '12.1-35.4',
        count: moderateCount,
        color: Colors.amber[700] ?? Colors.orange,
        percentage: total > 0 ? (moderateCount / total * 100) : 0,
      ),
      _CategoryData(
        label: 'UNHEALTHY',
        threshold: '35.5-55.4',
        count: unhealthyCount,
        color: Colors.deepOrange,
        percentage: total > 0 ? (unhealthyCount / total * 100) : 0,
      ),
      _CategoryData(
        label: 'POOR',
        threshold: '> 55.4 µg/m³',
        count: poorCount,
        color: Colors.purple,
        percentage: total > 0 ? (poorCount / total * 100) : 0,
      ),
    ];

    final int maxCount = [goodCount, moderateCount, unhealthyCount, poorCount].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Distribution',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: $total readings',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(
                categories: categories,
                maxCount: maxCount > 0 ? maxCount : 1,
                isDark: isDark,
                textColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.grey,
                gridColor: isDark ? Colors.grey[850]! : Colors.grey[200]!,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category Legend Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: categories.map((c) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        color: c.color,
                      ),
                    ),
                    Text(
                      '${c.count} (${c.percentage.toStringAsFixed(0)}%)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8.5,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  final String label;
  final String threshold;
  final int count;
  final Color color;
  final double percentage;

  _CategoryData({
    required this.label,
    required this.threshold,
    required this.count,
    required this.color,
    required this.percentage,
  });
}

class _BarChartPainter extends CustomPainter {
  final List<_CategoryData> categories;
  final int maxCount;
  final bool isDark;
  final Color textColor;
  final Color gridColor;

  _BarChartPainter({
    required this.categories,
    required this.maxCount,
    required this.isDark,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingBottom = 22.0;
    const double paddingTop = 26.0;
    const double paddingLeft = 28.0;
    const double paddingRight = 12.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingBottom - paddingTop;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Grid lines & labels (3 intervals)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    const int divisions = 3;
    for (int i = 0; i <= divisions; i++) {
      final double fraction = i / divisions;
      final double y = paddingTop + chartHeight - (fraction * chartHeight);
      final int countLabel = (fraction * maxCount).round();

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final textSpan = TextSpan(text: '$countLabel', style: textStyle);
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 4, y - tp.height / 2));
    }

    // Draw bars
    final int n = categories.length;
    final double slotWidth = chartWidth / n;
    final double barWidth = (slotWidth * 0.52).clamp(16.0, 36.0);

    for (int i = 0; i < n; i++) {
      final cat = categories[i];
      final double centerX = paddingLeft + (i * slotWidth) + (slotWidth / 2);
      final double barHeight = maxCount > 0 ? (cat.count / maxCount * chartHeight) : 0;
      final double barTop = paddingTop + chartHeight - barHeight;
      final double barLeft = centerX - (barWidth / 2);

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight > 2 ? barHeight : 2),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      // Gradient bar fill
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cat.color,
            cat.color.withValues(alpha: 0.65),
          ],
        ).createShader(rect.outerRect)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, barPaint);

      // Count label on top of bar
      final countSpan = TextSpan(
        text: '${cat.count}',
        style: TextStyle(
          color: cat.count > 0 ? cat.color : textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final countTp = TextPainter(text: countSpan, textDirection: TextDirection.ltr);
      countTp.layout();
      countTp.paint(
        canvas,
        Offset(centerX - (countTp.width / 2), barTop - countTp.height - 3),
      );

      // Bottom Category Label
      final labelSpan = TextSpan(
        text: cat.label.length > 5 ? cat.label.substring(0, 4) : cat.label,
        style: textStyle.copyWith(fontSize: 8.5, fontWeight: FontWeight.bold),
      );
      final labelTp = TextPainter(text: labelSpan, textDirection: TextDirection.ltr);
      labelTp.layout();
      labelTp.paint(
        canvas,
        Offset(centerX - (labelTp.width / 2), paddingTop + chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.maxCount != maxCount ||
        oldDelegate.isDark != isDark ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor;
  }
}
