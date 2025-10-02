class BabyGrowthRecord {
  const BabyGrowthRecord({
    this.id,
    required this.babyId,
    required this.recordedAt,
    this.heightCm,
    this.weightKg,
    this.headCircumferenceCm,
    this.heightPercentile,
    this.weightPercentile,
    this.headCircumferencePercentile,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int babyId;
  final DateTime recordedAt;
  final double? heightCm;
  final double? weightKg;
  final double? headCircumferenceCm;
  final double? heightPercentile;
  final double? weightPercentile;
  final double? headCircumferencePercentile;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BabyGrowthRecord copyWith({
    int? id,
    int? babyId,
    DateTime? recordedAt,
    double? heightCm,
    double? weightKg,
    double? headCircumferenceCm,
    double? heightPercentile,
    double? weightPercentile,
    double? headCircumferencePercentile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BabyGrowthRecord(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      recordedAt: recordedAt ?? this.recordedAt,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      headCircumferenceCm: headCircumferenceCm ?? this.headCircumferenceCm,
      heightPercentile: heightPercentile ?? this.heightPercentile,
      weightPercentile: weightPercentile ?? this.weightPercentile,
      headCircumferencePercentile:
          headCircumferencePercentile ?? this.headCircumferencePercentile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baby_id': babyId,
      'recorded_at': recordedAt.millisecondsSinceEpoch,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'head_circumference_cm': headCircumferenceCm,
      'height_percentile': heightPercentile,
      'weight_percentile': weightPercentile,
      'head_circumference_percentile': headCircumferencePercentile,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory BabyGrowthRecord.fromJson(Map<String, dynamic> json) {
    return BabyGrowthRecord(
      id: json['id'] as int?,
      babyId: json['baby_id'] as int,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(json['recorded_at'] as int),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      headCircumferenceCm:
          (json['head_circumference_cm'] as num?)?.toDouble(),
      heightPercentile: (json['height_percentile'] as num?)?.toDouble(),
      weightPercentile: (json['weight_percentile'] as num?)?.toDouble(),
      headCircumferencePercentile:
          (json['head_circumference_percentile'] as num?)?.toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
    );
  }
}
