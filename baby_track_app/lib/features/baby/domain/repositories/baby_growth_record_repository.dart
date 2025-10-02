import 'package:baby_track_app/features/baby/domain/models/baby_growth_record.dart';

abstract class BabyGrowthRecordRepository {
  Future<List<BabyGrowthRecord>> getRecordsForBaby(int babyId);

  Future<BabyGrowthRecord> createRecord(BabyGrowthRecord record);

  Future<BabyGrowthRecord> updateRecord(BabyGrowthRecord record);

  Future<void> deleteRecord(int id);
}
