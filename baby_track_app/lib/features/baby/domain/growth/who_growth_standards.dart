import 'dart:math' as math;

enum BabyGender { male, female }

enum GrowthMetric { weight, height, headCircumference }

class WhoGrowthEntry {
  const WhoGrowthEntry({
    required this.ageMonths,
    required this.p3,
    required this.p15,
    required this.p50,
    required this.p85,
    required this.p97,
  });

  final double ageMonths;
  final double p3;
  final double p15;
  final double p50;
  final double p85;
  final double p97;

  List<double> get percentileValues => [p3, p15, p50, p85, p97];
}

class WhoGrowthStandards {
  const WhoGrowthStandards._();

  static List<WhoGrowthEntry> entriesFor({
    required BabyGender gender,
    required GrowthMetric metric,
  }) {
    switch (metric) {
      case GrowthMetric.weight:
        return gender == BabyGender.male
            ? _weightBoys0To24Months
            : _weightGirls0To24Months;
      case GrowthMetric.height:
        return gender == BabyGender.male
            ? _lengthBoys0To24Months
            : _lengthGirls0To24Months;
      case GrowthMetric.headCircumference:
        return gender == BabyGender.male
            ? _headBoys0To24Months
            : _headGirls0To24Months;
    }
  }

  static double? percentileForMeasurement({
    required double? measurement,
    required double ageMonths,
    required BabyGender gender,
    required GrowthMetric metric,
  }) {
    if (measurement == null) {
      return null;
    }
    final data = entriesFor(gender: gender, metric: metric);
    if (data.isEmpty) {
      return null;
    }
    final clampedAge = ageMonths.clamp(data.first.ageMonths, data.last.ageMonths);
    final _AgeBracket bracket = _resolveAgeBracket(data, clampedAge);
    final factor = bracket.upper.ageMonths == bracket.lower.ageMonths
        ? 0.0
        : (clampedAge - bracket.lower.ageMonths) /
            (bracket.upper.ageMonths - bracket.lower.ageMonths);

    final percentiles = [3.0, 15.0, 50.0, 85.0, 97.0];
    final values = <double>[];
    for (final getter in _valueGetters) {
      final lower = getter(bracket.lower);
      final upper = getter(bracket.upper);
      final interpolated = lower + (upper - lower) * factor;
      values.add(interpolated);
    }

    if (measurement <= values.first) {
      final slope = (values[1] - values.first) / (percentiles[1] - percentiles.first);
      final delta = (measurement - values.first) / slope;
      return math.max(0, percentiles.first + delta);
    }

    for (var i = 0; i < values.length - 1; i++) {
      final current = values[i];
      final next = values[i + 1];
      if (measurement <= next) {
        final slope = (next - current) / (percentiles[i + 1] - percentiles[i]);
        final delta = (measurement - current) / slope;
        return percentiles[i] + delta;
      }
    }

    final slope =
        (values.last - values[values.length - 2]) /
        (percentiles.last - percentiles[percentiles.length - 2]);
    final delta = (measurement - values.last) / slope;
    return math.min(100, percentiles.last + delta);
  }

  static _AgeBracket _resolveAgeBracket(List<WhoGrowthEntry> data, double ageMonths) {
    WhoGrowthEntry lower = data.first;
    WhoGrowthEntry upper = data.last;

    for (final entry in data) {
      if (entry.ageMonths <= ageMonths) {
        lower = entry;
      }
      if (entry.ageMonths >= ageMonths) {
        upper = entry;
        break;
      }
    }

    return _AgeBracket(lower: lower, upper: upper);
  }

  static final List<double Function(WhoGrowthEntry)> _valueGetters = [
    (entry) => entry.p3,
    (entry) => entry.p15,
    (entry) => entry.p50,
    (entry) => entry.p85,
    (entry) => entry.p97,
  ];

  static const List<WhoGrowthEntry> _lengthBoys0To24Months = [
    WhoGrowthEntry(ageMonths: 0, p3: 46.1, p15: 48.0, p50: 49.9, p85: 51.8, p97: 53.4),
    WhoGrowthEntry(ageMonths: 1, p3: 50.8, p15: 52.7, p50: 54.7, p85: 56.7, p97: 58.4),
    WhoGrowthEntry(ageMonths: 2, p3: 54.4, p15: 56.4, p50: 58.4, p85: 60.4, p97: 62.2),
    WhoGrowthEntry(ageMonths: 3, p3: 57.3, p15: 59.4, p50: 61.4, p85: 63.5, p97: 65.3),
    WhoGrowthEntry(ageMonths: 4, p3: 59.7, p15: 61.8, p50: 63.9, p85: 66.1, p97: 68.0),
    WhoGrowthEntry(ageMonths: 5, p3: 61.7, p15: 63.8, p50: 65.9, p85: 68.1, p97: 70.0),
    WhoGrowthEntry(ageMonths: 6, p3: 63.3, p15: 65.4, p50: 67.6, p85: 69.8, p97: 71.6),
    WhoGrowthEntry(ageMonths: 7, p3: 64.7, p15: 66.9, p50: 69.2, p85: 71.3, p97: 73.1),
    WhoGrowthEntry(ageMonths: 8, p3: 66.0, p15: 68.2, p50: 70.6, p85: 72.7, p97: 74.5),
    WhoGrowthEntry(ageMonths: 9, p3: 67.2, p15: 69.5, p50: 72.0, p85: 74.1, p97: 75.9),
    WhoGrowthEntry(ageMonths: 10, p3: 68.4, p15: 70.7, p50: 73.3, p85: 75.3, p97: 77.2),
    WhoGrowthEntry(ageMonths: 11, p3: 69.6, p15: 71.9, p50: 74.5, p85: 76.6, p97: 78.5),
    WhoGrowthEntry(ageMonths: 12, p3: 70.6, p15: 73.0, p50: 75.7, p85: 77.8, p97: 79.7),
    WhoGrowthEntry(ageMonths: 13, p3: 71.6, p15: 74.1, p50: 76.9, p85: 79.1, p97: 81.0),
    WhoGrowthEntry(ageMonths: 14, p3: 72.6, p15: 75.1, p50: 78.0, p85: 80.2, p97: 82.1),
    WhoGrowthEntry(ageMonths: 15, p3: 73.5, p15: 76.0, p50: 79.1, p85: 81.4, p97: 83.3),
    WhoGrowthEntry(ageMonths: 16, p3: 74.4, p15: 77.0, p50: 80.2, p85: 82.5, p97: 84.4),
    WhoGrowthEntry(ageMonths: 17, p3: 75.3, p15: 77.9, p50: 81.2, p85: 83.6, p97: 85.5),
    WhoGrowthEntry(ageMonths: 18, p3: 76.1, p15: 78.8, p50: 82.3, p85: 84.7, p97: 86.6),
    WhoGrowthEntry(ageMonths: 19, p3: 76.9, p15: 79.6, p50: 83.2, p85: 85.8, p97: 87.7),
    WhoGrowthEntry(ageMonths: 20, p3: 77.7, p15: 80.5, p50: 84.2, p85: 86.8, p97: 88.7),
    WhoGrowthEntry(ageMonths: 21, p3: 78.5, p15: 81.3, p50: 85.1, p85: 87.8, p97: 89.8),
    WhoGrowthEntry(ageMonths: 22, p3: 79.2, p15: 82.0, p50: 86.0, p85: 88.8, p97: 90.8),
    WhoGrowthEntry(ageMonths: 23, p3: 80.0, p15: 82.8, p50: 86.9, p85: 89.8, p97: 91.9),
    WhoGrowthEntry(ageMonths: 24, p3: 80.7, p15: 83.6, p50: 87.8, p85: 90.7, p97: 92.9),
  ];

  static const List<WhoGrowthEntry> _lengthGirls0To24Months = [
    WhoGrowthEntry(ageMonths: 0, p3: 45.4, p15: 47.3, p50: 49.1, p85: 51.0, p97: 52.7),
    WhoGrowthEntry(ageMonths: 1, p3: 49.8, p15: 51.7, p50: 53.7, p85: 55.6, p97: 57.3),
    WhoGrowthEntry(ageMonths: 2, p3: 53.0, p15: 55.0, p50: 57.1, p85: 59.1, p97: 60.9),
    WhoGrowthEntry(ageMonths: 3, p3: 55.6, p15: 57.7, p50: 59.8, p85: 61.9, p97: 63.8),
    WhoGrowthEntry(ageMonths: 4, p3: 57.8, p15: 59.9, p50: 62.0, p85: 64.2, p97: 66.1),
    WhoGrowthEntry(ageMonths: 5, p3: 59.6, p15: 61.8, p50: 64.0, p85: 66.2, p97: 68.1),
    WhoGrowthEntry(ageMonths: 6, p3: 61.2, p15: 63.5, p50: 65.7, p85: 67.9, p97: 69.8),
    WhoGrowthEntry(ageMonths: 7, p3: 62.7, p15: 65.0, p50: 67.3, p85: 69.5, p97: 71.4),
    WhoGrowthEntry(ageMonths: 8, p3: 64.0, p15: 66.4, p50: 68.7, p85: 71.0, p97: 72.9),
    WhoGrowthEntry(ageMonths: 9, p3: 65.3, p15: 67.7, p50: 70.1, p85: 72.4, p97: 74.3),
    WhoGrowthEntry(ageMonths: 10, p3: 66.5, p15: 69.0, p50: 71.5, p85: 73.8, p97: 75.8),
    WhoGrowthEntry(ageMonths: 11, p3: 67.7, p15: 70.3, p50: 72.8, p85: 75.2, p97: 77.2),
    WhoGrowthEntry(ageMonths: 12, p3: 68.9, p15: 71.5, p50: 74.0, p85: 76.5, p97: 78.5),
    WhoGrowthEntry(ageMonths: 13, p3: 70.0, p15: 72.7, p50: 75.3, p85: 77.8, p97: 79.9),
    WhoGrowthEntry(ageMonths: 14, p3: 71.0, p15: 73.8, p50: 76.5, p85: 79.1, p97: 81.2),
    WhoGrowthEntry(ageMonths: 15, p3: 72.0, p15: 74.9, p50: 77.7, p85: 80.4, p97: 82.5),
    WhoGrowthEntry(ageMonths: 16, p3: 73.0, p15: 76.0, p50: 78.9, p85: 81.7, p97: 83.8),
    WhoGrowthEntry(ageMonths: 17, p3: 74.0, p15: 77.0, p50: 80.1, p85: 82.9, p97: 85.1),
    WhoGrowthEntry(ageMonths: 18, p3: 74.9, p15: 78.0, p50: 81.2, p85: 84.1, p97: 86.3),
    WhoGrowthEntry(ageMonths: 19, p3: 75.8, p15: 79.0, p50: 82.3, p85: 85.3, p97: 87.5),
    WhoGrowthEntry(ageMonths: 20, p3: 76.7, p15: 80.0, p50: 83.4, p85: 86.5, p97: 88.7),
    WhoGrowthEntry(ageMonths: 21, p3: 77.5, p15: 80.9, p50: 84.5, p85: 87.7, p97: 89.9),
    WhoGrowthEntry(ageMonths: 22, p3: 78.4, p15: 81.9, p50: 85.5, p85: 88.9, p97: 91.1),
    WhoGrowthEntry(ageMonths: 23, p3: 79.2, p15: 82.8, p50: 86.6, p85: 90.0, p97: 92.2),
    WhoGrowthEntry(ageMonths: 24, p3: 80.0, p15: 83.7, p50: 87.6, p85: 91.1, p97: 93.4),
  ];

  static const List<WhoGrowthEntry> _weightBoys0To24Months = [
    WhoGrowthEntry(ageMonths: 0, p3: 2.5, p15: 2.9, p50: 3.3, p85: 3.9, p97: 4.4),
    WhoGrowthEntry(ageMonths: 1, p3: 3.4, p15: 3.9, p50: 4.5, p85: 5.2, p97: 5.8),
    WhoGrowthEntry(ageMonths: 2, p3: 4.4, p15: 5.0, p50: 5.6, p85: 6.4, p97: 7.0),
    WhoGrowthEntry(ageMonths: 3, p3: 5.1, p15: 5.8, p50: 6.4, p85: 7.2, p97: 7.9),
    WhoGrowthEntry(ageMonths: 4, p3: 5.6, p15: 6.4, p50: 7.0, p85: 7.9, p97: 8.6),
    WhoGrowthEntry(ageMonths: 5, p3: 6.0, p15: 6.9, p50: 7.5, p85: 8.4, p97: 9.1),
    WhoGrowthEntry(ageMonths: 6, p3: 6.4, p15: 7.3, p50: 7.9, p85: 8.9, p97: 9.6),
    WhoGrowthEntry(ageMonths: 7, p3: 6.7, p15: 7.6, p50: 8.3, p85: 9.3, p97: 10.0),
    WhoGrowthEntry(ageMonths: 8, p3: 7.0, p15: 7.9, p50: 8.6, p85: 9.6, p97: 10.4),
    WhoGrowthEntry(ageMonths: 9, p3: 7.2, p15: 8.2, p50: 8.9, p85: 10.0, p97: 10.7),
    WhoGrowthEntry(ageMonths: 10, p3: 7.5, p15: 8.4, p50: 9.2, p85: 10.3, p97: 11.0),
    WhoGrowthEntry(ageMonths: 11, p3: 7.7, p15: 8.7, p50: 9.4, p85: 10.5, p97: 11.3),
    WhoGrowthEntry(ageMonths: 12, p3: 7.9, p15: 8.9, p50: 9.6, p85: 10.8, p97: 11.5),
    WhoGrowthEntry(ageMonths: 13, p3: 8.1, p15: 9.1, p50: 9.9, p85: 11.0, p97: 11.8),
    WhoGrowthEntry(ageMonths: 14, p3: 8.3, p15: 9.3, p50: 10.1, p85: 11.3, p97: 12.1),
    WhoGrowthEntry(ageMonths: 15, p3: 8.5, p15: 9.5, p50: 10.3, p85: 11.5, p97: 12.3),
    WhoGrowthEntry(ageMonths: 16, p3: 8.7, p15: 9.7, p50: 10.5, p85: 11.8, p97: 12.6),
    WhoGrowthEntry(ageMonths: 17, p3: 8.9, p15: 9.9, p50: 10.7, p85: 12.0, p97: 12.8),
    WhoGrowthEntry(ageMonths: 18, p3: 9.1, p15: 10.1, p50: 10.9, p85: 12.2, p97: 13.1),
    WhoGrowthEntry(ageMonths: 19, p3: 9.2, p15: 10.3, p50: 11.1, p85: 12.5, p97: 13.3),
    WhoGrowthEntry(ageMonths: 20, p3: 9.4, p15: 10.5, p50: 11.3, p85: 12.7, p97: 13.6),
    WhoGrowthEntry(ageMonths: 21, p3: 9.6, p15: 10.7, p50: 11.5, p85: 12.9, p97: 13.8),
    WhoGrowthEntry(ageMonths: 22, p3: 9.8, p15: 10.9, p50: 11.7, p85: 13.2, p97: 14.1),
    WhoGrowthEntry(ageMonths: 23, p3: 10.0, p15: 11.1, p50: 11.9, p85: 13.4, p97: 14.3),
    WhoGrowthEntry(ageMonths: 24, p3: 10.2, p15: 11.3, p50: 12.1, p85: 13.7, p97: 14.6),
  ];

  static const List<WhoGrowthEntry> _weightGirls0To24Months = [
    WhoGrowthEntry(ageMonths: 0, p3: 2.4, p15: 2.8, p50: 3.2, p85: 3.7, p97: 4.2),
    WhoGrowthEntry(ageMonths: 1, p3: 3.2, p15: 3.6, p50: 4.2, p85: 4.8, p97: 5.3),
    WhoGrowthEntry(ageMonths: 2, p3: 4.0, p15: 4.5, p50: 5.1, p85: 5.8, p97: 6.4),
    WhoGrowthEntry(ageMonths: 3, p3: 4.6, p15: 5.1, p50: 5.7, p85: 6.5, p97: 7.1),
    WhoGrowthEntry(ageMonths: 4, p3: 5.1, p15: 5.6, p50: 6.2, p85: 7.0, p97: 7.6),
    WhoGrowthEntry(ageMonths: 5, p3: 5.4, p15: 6.0, p50: 6.6, p85: 7.5, p97: 8.1),
    WhoGrowthEntry(ageMonths: 6, p3: 5.7, p15: 6.3, p50: 6.9, p85: 7.9, p97: 8.4),
    WhoGrowthEntry(ageMonths: 7, p3: 5.9, p15: 6.6, p50: 7.2, p85: 8.2, p97: 8.8),
    WhoGrowthEntry(ageMonths: 8, p3: 6.1, p15: 6.8, p50: 7.4, p85: 8.5, p97: 9.1),
    WhoGrowthEntry(ageMonths: 9, p3: 6.3, p15: 7.0, p50: 7.6, p85: 8.7, p97: 9.4),
    WhoGrowthEntry(ageMonths: 10, p3: 6.5, p15: 7.3, p50: 7.8, p85: 9.0, p97: 9.7),
    WhoGrowthEntry(ageMonths: 11, p3: 6.6, p15: 7.4, p50: 8.0, p85: 9.2, p97: 9.9),
    WhoGrowthEntry(ageMonths: 12, p3: 6.8, p15: 7.6, p50: 8.2, p85: 9.4, p97: 10.1),
    WhoGrowthEntry(ageMonths: 13, p3: 7.0, p15: 7.8, p50: 8.4, p85: 9.6, p97: 10.3),
    WhoGrowthEntry(ageMonths: 14, p3: 7.1, p15: 8.0, p50: 8.6, p85: 9.8, p97: 10.5),
    WhoGrowthEntry(ageMonths: 15, p3: 7.3, p15: 8.1, p50: 8.7, p85: 10.0, p97: 10.7),
    WhoGrowthEntry(ageMonths: 16, p3: 7.4, p15: 8.3, p50: 8.9, p85: 10.2, p97: 10.9),
    WhoGrowthEntry(ageMonths: 17, p3: 7.6, p15: 8.4, p50: 9.1, p85: 10.4, p97: 11.1),
    WhoGrowthEntry(ageMonths: 18, p3: 7.7, p15: 8.6, p50: 9.2, p85: 10.5, p97: 11.3),
    WhoGrowthEntry(ageMonths: 19, p3: 7.9, p15: 8.7, p50: 9.4, p85: 10.7, p97: 11.5),
    WhoGrowthEntry(ageMonths: 20, p3: 8.0, p15: 8.9, p50: 9.5, p85: 10.9, p97: 11.7),
    WhoGrowthEntry(ageMonths: 21, p3: 8.1, p15: 9.0, p50: 9.7, p85: 11.1, p97: 11.9),
    WhoGrowthEntry(ageMonths: 22, p3: 8.3, p15: 9.2, p50: 9.8, p85: 11.3, p97: 12.1),
    WhoGrowthEntry(ageMonths: 23, p3: 8.4, p15: 9.3, p50: 10.0, p85: 11.5, p97: 12.3),
    WhoGrowthEntry(ageMonths: 24, p3: 8.5, p15: 9.5, p50: 10.1, p85: 11.7, p97: 12.5),
  ];

  static const List<WhoGrowthEntry> _headBoys0To24Months = [
    WhoGrowthEntry(ageMonths: 0, p3: 32.1, p15: 33.2, p50: 34.5, p85: 35.9, p97: 37.0),
    WhoGrowthEntry(ageMonths: 1, p3: 35.0, p15: 36.1, p50: 37.3, p85: 38.6, p97: 39.7),
    WhoGrowthEntry(ageMonths: 2, p3: 37.0, p15: 38.1, p50: 39.1, p85: 40.5, p97: 41.6),
    WhoGrowthEntry(ageMonths: 3, p3: 38.3, p15: 39.3, p50: 40.5, p85: 41.8, p97: 42.9),
    WhoGrowthEntry(ageMonths: 4, p3: 39.3, p15: 40.3, p50: 41.5, p85: 42.8, p97: 43.9),
    WhoGrowthEntry(ageMonths: 5, p3: 40.1, p15: 41.1, p50: 42.2, p85: 43.6, p97: 44.8),
    WhoGrowthEntry(ageMonths: 6, p3: 40.7, p15: 41.8, p50: 42.8, p85: 44.2, p97: 45.4),
    WhoGrowthEntry(ageMonths: 7, p3: 41.2, p15: 42.3, p50: 43.3, p85: 44.7, p97: 45.9),
    WhoGrowthEntry(ageMonths: 8, p3: 41.6, p15: 42.7, p50: 43.7, p85: 45.1, p97: 46.3),
    WhoGrowthEntry(ageMonths: 9, p3: 41.9, p15: 43.0, p50: 44.0, p85: 45.4, p97: 46.7),
    WhoGrowthEntry(ageMonths: 10, p3: 42.2, p15: 43.3, p50: 44.3, p85: 45.7, p97: 47.0),
    WhoGrowthEntry(ageMonths: 11, p3: 42.5, p15: 43.5, p50: 44.5, p85: 46.0, p97: 47.3),
    WhoGrowthEntry(ageMonths: 12, p3: 42.7, p15: 43.7, p50: 44.7, p85: 46.2, p97: 47.5),
    WhoGrowthEntry(ageMonths: 13, p3: 42.9, p15: 43.9, p50: 44.9, p85: 46.4, p97: 47.7),
    WhoGrowthEntry(ageMonths: 14, p3: 43.1, p15: 44.1, p50: 45.1, p85: 46.6, p97: 47.9),
    WhoGrowthEntry(ageMonths: 15, p3: 43.2, p15: 44.2, p50: 45.3, p85: 46.8, p97: 48.1),
    WhoGrowthEntry(ageMonths: 16, p3: 43.4, p15: 44.4, p50: 45.4, p85: 47.0, p97: 48.2),
    WhoGrowthEntry(ageMonths: 17, p3: 43.5, p15: 44.5, p50: 45.5, p85: 47.1, p97: 48.4),
    WhoGrowthEntry(ageMonths: 18, p3: 43.6, p15: 44.6, p50: 45.7, p85: 47.3, p97: 48.5),
    WhoGrowthEntry(ageMonths: 19, p3: 43.7, p15: 44.7, p50: 45.8, p85: 47.4, p97: 48.6),
    WhoGrowthEntry(ageMonths: 20, p3: 43.8, p15: 44.8, p50: 45.9, p85: 47.5, p97: 48.7),
    WhoGrowthEntry(ageMonths: 21, p3: 43.9, p15: 44.9, p50: 46.0, p85: 47.6, p97: 48.8),
    WhoGrowthEntry(ageMonths: 22, p3: 44.0, p15: 45.0, p50: 46.1, p85: 47.7, p97: 48.9),
    WhoGrowthEntry(ageMonths: 23, p3: 44.1, p15: 45.1, p50: 46.2, p85: 47.8, p97: 49.0),
    WhoGrowthEntry(ageMonths: 24, p3: 44.2, p15: 45.2, p50: 46.3, p85: 47.9, p97: 49.1),
  ];

  static const List<WhoGrowthEntry> _headGirls0To24Months = [
    WhoGrowthEntry(ageMonths: 0, p3: 31.7, p15: 32.7, p50: 33.9, p85: 35.2, p97: 36.2),
    WhoGrowthEntry(ageMonths: 1, p3: 34.2, p15: 35.2, p50: 36.4, p85: 37.7, p97: 38.8),
    WhoGrowthEntry(ageMonths: 2, p3: 35.8, p15: 36.8, p50: 37.9, p85: 39.1, p97: 40.3),
    WhoGrowthEntry(ageMonths: 3, p3: 36.9, p15: 37.9, p50: 39.0, p85: 40.3, p97: 41.4),
    WhoGrowthEntry(ageMonths: 4, p3: 37.7, p15: 38.7, p50: 39.8, p85: 41.1, p97: 42.3),
    WhoGrowthEntry(ageMonths: 5, p3: 38.3, p15: 39.4, p50: 40.4, p85: 41.8, p97: 43.0),
    WhoGrowthEntry(ageMonths: 6, p3: 38.8, p15: 39.9, p50: 41.0, p85: 42.3, p97: 43.5),
    WhoGrowthEntry(ageMonths: 7, p3: 39.2, p15: 40.3, p50: 41.3, p85: 42.7, p97: 43.9),
    WhoGrowthEntry(ageMonths: 8, p3: 39.5, p15: 40.6, p50: 41.7, p85: 43.0, p97: 44.3),
    WhoGrowthEntry(ageMonths: 9, p3: 39.8, p15: 40.9, p50: 42.0, p85: 43.3, p97: 44.6),
    WhoGrowthEntry(ageMonths: 10, p3: 40.0, p15: 41.1, p50: 42.2, p85: 43.5, p97: 44.9),
    WhoGrowthEntry(ageMonths: 11, p3: 40.2, p15: 41.3, p50: 42.4, p85: 43.7, p97: 45.1),
    WhoGrowthEntry(ageMonths: 12, p3: 40.4, p15: 41.5, p50: 42.6, p85: 43.9, p97: 45.3),
    WhoGrowthEntry(ageMonths: 13, p3: 40.5, p15: 41.6, p50: 42.7, p85: 44.0, p97: 45.4),
    WhoGrowthEntry(ageMonths: 14, p3: 40.7, p15: 41.8, p50: 42.9, p85: 44.2, p97: 45.6),
    WhoGrowthEntry(ageMonths: 15, p3: 40.8, p15: 41.9, p50: 43.0, p85: 44.3, p97: 45.7),
    WhoGrowthEntry(ageMonths: 16, p3: 40.9, p15: 42.0, p50: 43.1, p85: 44.4, p97: 45.8),
    WhoGrowthEntry(ageMonths: 17, p3: 41.0, p15: 42.1, p50: 43.2, p85: 44.5, p97: 45.9),
    WhoGrowthEntry(ageMonths: 18, p3: 41.1, p15: 42.2, p50: 43.3, p85: 44.6, p97: 46.0),
    WhoGrowthEntry(ageMonths: 19, p3: 41.2, p15: 42.3, p50: 43.4, p85: 44.7, p97: 46.1),
    WhoGrowthEntry(ageMonths: 20, p3: 41.3, p15: 42.4, p50: 43.5, p85: 44.8, p97: 46.2),
    WhoGrowthEntry(ageMonths: 21, p3: 41.4, p15: 42.5, p50: 43.6, p85: 44.9, p97: 46.3),
    WhoGrowthEntry(ageMonths: 22, p3: 41.5, p15: 42.6, p50: 43.7, p85: 44.9, p97: 46.4),
    WhoGrowthEntry(ageMonths: 23, p3: 41.6, p15: 42.7, p50: 43.8, p85: 45.0, p97: 46.5),
    WhoGrowthEntry(ageMonths: 24, p3: 41.7, p15: 42.8, p50: 43.9, p85: 45.1, p97: 46.6),
  ];
}

class _AgeBracket {
  const _AgeBracket({required this.lower, required this.upper});

  final WhoGrowthEntry lower;
  final WhoGrowthEntry upper;
}
