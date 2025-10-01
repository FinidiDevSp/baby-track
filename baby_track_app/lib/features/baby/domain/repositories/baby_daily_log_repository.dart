import 'package:baby_track_app/features/baby/domain/models/baby_daily_log.dart';

abstract class BabyDailyLogRepository {
  Future<BabyDailyLog> createLog(BabyDailyLog log);
  Future<List<BabyDailyLog>> getLogsForBabyOnDate(int babyId, DateTime date);
  Future<List<BabyDailyLog>> getRecentLogsForBaby(int babyId, {int limit = 20});
}
