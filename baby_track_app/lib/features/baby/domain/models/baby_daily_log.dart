class BabyDailyLog {
  const BabyDailyLog({
    this.id,
    required this.babyId,
    required this.logDay,
    required this.loggedAt,
    this.intakeMl,
    this.didPoop = false,
    this.showered = false,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int babyId;
  final DateTime logDay;
  final DateTime loggedAt;
  final int? intakeMl;
  final bool didPoop;
  final bool showered;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BabyDailyLog copyWith({
    int? id,
    int? babyId,
    DateTime? logDay,
    DateTime? loggedAt,
    int? intakeMl,
    bool? didPoop,
    bool? showered,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BabyDailyLog(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      logDay: logDay ?? this.logDay,
      loggedAt: loggedAt ?? this.loggedAt,
      intakeMl: intakeMl ?? this.intakeMl,
      didPoop: didPoop ?? this.didPoop,
      showered: showered ?? this.showered,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baby_id': babyId,
      'log_day': DateTime(logDay.year, logDay.month, logDay.day).millisecondsSinceEpoch,
      'logged_at': loggedAt.millisecondsSinceEpoch,
      'intake_ml': intakeMl,
      'did_poop': didPoop ? 1 : 0,
      'showered': showered ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory BabyDailyLog.fromJson(Map<String, dynamic> json) {
    return BabyDailyLog(
      id: json['id'] as int?,
      babyId: json['baby_id'] as int,
      logDay: DateTime.fromMillisecondsSinceEpoch(json['log_day'] as int),
      loggedAt: DateTime.fromMillisecondsSinceEpoch(json['logged_at'] as int),
      intakeMl: json['intake_ml'] as int?,
      didPoop: (json['did_poop'] as int) == 1,
      showered: (json['showered'] as int) == 1,
      notes: json['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : null,
    );
  }
}
