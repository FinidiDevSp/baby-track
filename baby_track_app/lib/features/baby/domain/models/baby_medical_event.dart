class BabyMedicalEvent {
  const BabyMedicalEvent({
    this.id,
    required this.babyId,
    required this.title,
    required this.eventType,
    required this.scheduledAt,
    this.location,
    this.notes,
    this.reminderEnabled = true,
    this.reminderMinutesBefore = 1440,
    this.reminderSentAt,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int babyId;
  final String title;
  final String eventType;
  final DateTime scheduledAt;
  final String? location;
  final String? notes;
  final bool reminderEnabled;
  final int reminderMinutesBefore;
  final DateTime? reminderSentAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BabyMedicalEvent copyWith({
    int? id,
    int? babyId,
    String? title,
    String? eventType,
    DateTime? scheduledAt,
    String? location,
    String? notes,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    DateTime? reminderSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BabyMedicalEvent(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baby_id': babyId,
      'title': title,
      'event_type': eventType,
      'scheduled_at': scheduledAt.millisecondsSinceEpoch,
      'location': location,
      'notes': notes,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_minutes_before': reminderMinutesBefore,
      'reminder_sent_at': reminderSentAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory BabyMedicalEvent.fromJson(Map<String, dynamic> json) {
    return BabyMedicalEvent(
      id: json['id'] as int?,
      babyId: json['baby_id'] as int,
      title: json['title'] as String,
      eventType: json['event_type'] as String,
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(json['scheduled_at'] as int),
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      reminderEnabled: (json['reminder_enabled'] as int? ?? 1) == 1,
      reminderMinutesBefore: json['reminder_minutes_before'] as int? ?? 1440,
      reminderSentAt: json['reminder_sent_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['reminder_sent_at'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
    );
  }
}
