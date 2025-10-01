import 'package:baby_track_app/features/baby/domain/models/baby_daily_log.dart';
import 'package:baby_track_app/features/baby/domain/repositories/baby_daily_log_repository.dart';
import 'package:baby_track_app/shared/data/database/database_helper.dart';

class BabyDailyLogRepositoryImpl implements BabyDailyLogRepository {
  BabyDailyLogRepositoryImpl({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<BabyDailyLog> createLog(BabyDailyLog log) async {
    final db = await _databaseHelper.database;
    final normalizedDay = DateTime(log.logDay.year, log.logDay.month, log.logDay.day);
    final normalizedDateTime = DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
      log.loggedAt.hour,
      log.loggedAt.minute,
    );
    final now = DateTime.now();

    final logToInsert = log.copyWith(
      logDay: normalizedDay,
      loggedAt: normalizedDateTime,
      createdAt: now,
      updatedAt: now,
    );

    final id = await db.insert('baby_daily_logs', logToInsert.toJson()..remove('id'));

    return logToInsert.copyWith(id: id);
  }

  @override
  Future<List<BabyDailyLog>> getLogsForBabyOnDate(int babyId, DateTime date) async {
    final db = await _databaseHelper.database;
    final normalizedDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

    final result = await db.query(
      'baby_daily_logs',
      where: 'baby_id = ? AND log_day = ?',
      whereArgs: [babyId, normalizedDay],
      orderBy: 'logged_at ASC',
    );

    return result.map(BabyDailyLog.fromJson).toList();
  }

  @override
  Future<List<BabyDailyLog>> getRecentLogsForBaby(int babyId, {int limit = 20}) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'baby_daily_logs',
      where: 'baby_id = ?',
      whereArgs: [babyId],
      orderBy: 'logged_at DESC',
      limit: limit,
    );

    return result.map(BabyDailyLog.fromJson).toList();
  }

  @override
  Future<List<BabyDailyLog>> getAllLogsForBaby(int babyId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'baby_daily_logs',
      where: 'baby_id = ?',
      whereArgs: [babyId],
      orderBy: 'log_day DESC, logged_at DESC',
    );

    return result.map(BabyDailyLog.fromJson).toList();
  }
}
