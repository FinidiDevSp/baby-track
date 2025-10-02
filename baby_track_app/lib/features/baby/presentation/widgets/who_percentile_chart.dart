import 'dart:math' as math;

import 'package:baby_track_app/features/baby/domain/growth/who_growth_standards.dart';
import 'package:flutter/material.dart';

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
        return _WhoChartPainterWidget(data: data, measurement: measurement, ageMonths: ageMonths);
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
  static const double _focusSpanMonths = 14;

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

    final dataMinAge = data.first.ageMonths;
    final dataMaxAge = data.last.ageMonths;

    double minAge = dataMinAge;
    double maxAge = dataMaxAge;
    final totalSpan = dataMaxAge - dataMinAge;
    if (totalSpan > _focusSpanMonths) {
      final clampedAge = ageMonths.clamp(dataMinAge, dataMaxAge);
      var start = clampedAge - _focusSpanMonths / 2;
      var end = clampedAge + _focusSpanMonths / 2;

      if (start < dataMinAge) {
        end += dataMinAge - start;
        start = dataMinAge;
      }
      if (end > dataMaxAge) {
        start -= end - dataMaxAge;
        end = dataMaxAge;
      }

      minAge = start.clamp(dataMinAge, dataMaxAge - _focusSpanMonths);
      maxAge = (minAge + _focusSpanMonths).clamp(minAge, dataMaxAge);
      if (maxAge - minAge < _focusSpanMonths) {
        minAge = math.max(dataMinAge, dataMaxAge - _focusSpanMonths);
        maxAge = dataMaxAge;
      }
    }

    final visibleData = data
        .where((entry) => entry.ageMonths >= minAge && entry.ageMonths <= maxAge)
        .toList(growable: true);

    if (visibleData.isNotEmpty) {
      final firstIndex = data.indexOf(visibleData.first);
      if (visibleData.first.ageMonths > minAge && firstIndex > 0) {
        visibleData.insert(0, data[firstIndex - 1]);
      }
      final lastIndex = data.indexOf(visibleData.last);
      if (visibleData.last.ageMonths < maxAge && lastIndex < data.length - 1) {
        visibleData.add(data[lastIndex + 1]);
      }
    }

    final points = visibleData.length >= 2 ? visibleData : data;
    if (points == data) {
      minAge = dataMinAge;
      maxAge = dataMaxAge;
    }

    double minValue = points.first.p3;
    double maxValue = points.first.p97;
    for (final entry in points) {
      minValue = math.min(minValue, entry.p3);
      maxValue = math.max(maxValue, entry.p97);
    }
    final range = maxValue - minValue;
    final verticalPadding = range * 0.05;
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
    canvas.drawLine(
      Offset(_paddingLeft, baselineY),
      Offset(_paddingLeft + chartWidth, baselineY),
      axisPaint,
    );

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
    for (var entryIndex = 0; entryIndex < points.length; entryIndex++) {
      final entry = points[entryIndex];
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
      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()
          ..color = measurementColor.withOpacity(0.18)
          ..style = PaintingStyle.fill,
      );
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
