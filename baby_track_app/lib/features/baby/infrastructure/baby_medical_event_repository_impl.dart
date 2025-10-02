import 'package:baby_track_app/features/baby/domain/models/baby_medical_event.dart';
import 'package:baby_track_app/features/baby/domain/repositories/baby_medical_event_repository.dart';
import 'package:baby_track_app/shared/data/database/database_helper.dart';

class BabyMedicalEventRepositoryImpl implements BabyMedicalEventRepository {
  BabyMedicalEventRepositoryImpl({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<BabyMedicalEvent> createEvent(BabyMedicalEvent event) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();

    final normalizedDateTime = DateTime(
      event.scheduledAt.year,
      event.scheduledAt.month,
      event.scheduledAt.day,
      event.scheduledAt.hour,
      event.scheduledAt.minute,
    );

    final eventToInsert = event.copyWith(
      scheduledAt: normalizedDateTime,
      createdAt: now,
      updatedAt: now,
    );

    final id = await db.insert(
      'baby_medical_events',
      eventToInsert.toJson()..remove('id'),
    );

    return eventToInsert.copyWith(id: id);
  }

  @override
  Future<BabyMedicalEvent> updateEvent(BabyMedicalEvent event) async {
    if (event.id == null) {
      throw ArgumentError('Cannot update event without id');
    }
    final db = await _databaseHelper.database;
    final updated = event.copyWith(updatedAt: DateTime.now());
    await db.update(
      'baby_medical_events',
      updated.toJson(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    return updated;
  }

  @override
  Future<void> deleteEvent(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('baby_medical_events', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<BabyMedicalEvent>> getEventsForBaby(int babyId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'baby_medical_events',
      where: 'baby_id = ?',
      whereArgs: [babyId],
      orderBy: 'scheduled_at ASC',
    );
    return result.map(BabyMedicalEvent.fromJson).toList();
  }

  @override
  Future<List<BabyMedicalEvent>> getEventsForBabyOnDate(int babyId, DateTime date) async {
    final db = await _databaseHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.query(
      'baby_medical_events',
      where: 'baby_id = ? AND scheduled_at >= ? AND scheduled_at < ?',
      whereArgs: [
        babyId,
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'scheduled_at ASC',
    );

    return result.map(BabyMedicalEvent.fromJson).toList();
  }

  @override
  Future<List<BabyMedicalEvent>> getUpcomingEventsForBaby(
    int babyId, {
    Duration within = const Duration(days: 7),
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final limit = now.add(within);

    final result = await db.query(
      'baby_medical_events',
      where: 'baby_id = ? AND scheduled_at >= ? AND scheduled_at <= ?',
      whereArgs: [
        babyId,
        now.millisecondsSinceEpoch,
        limit.millisecondsSinceEpoch,
      ],
      orderBy: 'scheduled_at ASC',
    );

    return result.map(BabyMedicalEvent.fromJson).toList();
  }

  @override
  Future<void> markReminderSent(int eventId, {DateTime? sentAt}) async {
    final db = await _databaseHelper.database;
    await db.update(
      'baby_medical_events',
      {
        'reminder_sent_at': (sentAt ?? DateTime.now()).millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }
}
