import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/growth/who_growth_standards.dart';

class WhoPercentileChart extends StatelessWidget {
  const WhoPercentileChart({
    super.key,
    required this.metric,
    required this.gender,
    required this.measurement,
    required this.ageMonths,
  });

  final GrowthMetric metric;
  final BabyGender gender;
  final double? measurement;
  final double ageMonths;

  @override
  Widget build(BuildContext context) {
    final data = WhoGrowthStandards.entriesFor(gender: gender, metric: metric);
    return LayoutBuilder(
      builder: (context, constraints) {
        return _WhoChartPainterWidget(
          data: data,
          measurement: measurement,
          ageMonths: ageMonths,
        );
      },
    );
  }
}

class _WhoChartPainterWidget extends StatelessWidget {
  const _WhoChartPainterWidget({
    required this.data,
    required this.measurement,
    required this.ageMonths,
  });

  final List<WhoGrowthEntry> data;
  final double? measurement;
  final double ageMonths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomPaint(
      painter: _WhoChartPainter(
        data: data,
        measurement: measurement,
        ageMonths: ageMonths,
        axisColor: colorScheme.outlineVariant.withOpacity(0.6),
        percentileColors: [
          colorScheme.error.withOpacity(0.45),
          colorScheme.tertiary.withOpacity(0.55),
          colorScheme.primary,
          colorScheme.secondary,
          colorScheme.primary.withOpacity(0.8),
        ],
        measurementColor: colorScheme.primary,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _WhoChartPainter extends CustomPainter {
  _WhoChartPainter({
    required this.data,
    required this.measurement,
    required this.ageMonths,
    required this.axisColor,
    required this.percentileColors,
    required this.measurementColor,
  });

  final List<WhoGrowthEntry> data;
  final double? measurement;
  final double ageMonths;
  final Color axisColor;
  final List<Color> percentileColors;
  final Color measurementColor;

  static const double _paddingLeft = 36;
  static const double _paddingRight = 16;
  static const double _paddingTop = 16;
  static const double _paddingBottom = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      return;
    }

    final chartWidth = size.width - _paddingLeft - _paddingRight;
    final chartHeight = size.height - _paddingTop - _paddingBottom;
    if (chartWidth <= 0 || chartHeight <= 0) {
      return;
    }

    final minAge = data.first.ageMonths;
    final maxAge = data.last.ageMonths;
    double minValue = data.first.p3;
    double maxValue = data.first.p97;
    for (final entry in data) {
      minValue = math.min(minValue, entry.p3);
      maxValue = math.max(maxValue, entry.p97);
    }
    final range = maxValue - minValue;
    final verticalPadding = range * 0.08;
    minValue -= verticalPadding;
    maxValue += verticalPadding;

    double toChartX(double age) {
      final normalized = (age - minAge) / (maxAge - minAge);
      return _paddingLeft + normalized * chartWidth;
    }

    double toChartY(double value) {
      final normalized = (value - minValue) / (maxValue - minValue);
      return _paddingTop + (1 - normalized) * chartHeight;
    }

    final axisPaint = Paint()
      ..color = axisColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw axes.
    final baselineY = _paddingTop + chartHeight;
    canvas.drawLine(Offset(_paddingLeft, _paddingTop), Offset(_paddingLeft, baselineY), axisPaint);
    canvas.drawLine(Offset(_paddingLeft, baselineY), Offset(_paddingLeft + chartWidth, baselineY), axisPaint);

    // Horizontal grid lines
    final gridPaint = Paint()
      ..color = axisColor.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    const gridCount = 4;
    for (var i = 1; i <= gridCount; i++) {
      final y = _paddingTop + chartHeight * (i / (gridCount + 1));
      canvas.drawLine(Offset(_paddingLeft, y), Offset(_paddingLeft + chartWidth, y), gridPaint);
    }

    final percentilePaths = List.generate(percentileColors.length, (_) => Path());
    for (var entryIndex = 0; entryIndex < data.length; entryIndex++) {
      final entry = data[entryIndex];
      final x = toChartX(entry.ageMonths);
      final values = entry.percentileValues;
      for (var i = 0; i < values.length; i++) {
        final y = toChartY(values[i]);
        final path = percentilePaths[i];
        if (entryIndex == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }

    for (var i = 0; i < percentilePaths.length; i++) {
      final paint = Paint()
        ..color = percentileColors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 2 ? 2.4 : 1.6;
      canvas.drawPath(percentilePaths[i], paint);
    }

    if (measurement != null) {
      final clampedAge = ageMonths.clamp(minAge, maxAge);
      final x = toChartX(clampedAge);
      final y = toChartY(measurement!.clamp(minValue, maxValue));

      final markerPaint = Paint()
        ..color = measurementColor.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(x, _paddingTop), Offset(x, baselineY), markerPaint);

      final pointPaint = Paint()..color = measurementColor;
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 8, Paint()
        ..color = measurementColor.withOpacity(0.18)
        ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _WhoChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.measurement != measurement ||
        oldDelegate.ageMonths != ageMonths ||
        oldDelegate.axisColor != axisColor;
  }
}
