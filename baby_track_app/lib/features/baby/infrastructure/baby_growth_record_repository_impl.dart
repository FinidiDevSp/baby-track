import 'package:baby_track_app/features/baby/domain/models/baby_growth_record.dart';
import 'package:baby_track_app/features/baby/domain/repositories/baby_growth_record_repository.dart';
import 'package:baby_track_app/shared/data/database/database_helper.dart';

class BabyGrowthRecordRepositoryImpl implements BabyGrowthRecordRepository {
  BabyGrowthRecordRepositoryImpl({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  @override
  Future<BabyGrowthRecord> createRecord(BabyGrowthRecord record) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final recordToInsert = record.copyWith(createdAt: now, updatedAt: now);
    final id = await db.insert(
      'baby_growth_records',
      recordToInsert.toJson()..remove('id'),
    );
    return recordToInsert.copyWith(id: id);
  }

  @override
  Future<void> deleteRecord(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('baby_growth_records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<BabyGrowthRecord>> getRecordsForBaby(int babyId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'baby_growth_records',
      where: 'baby_id = ?',
      whereArgs: [babyId],
      orderBy: 'recorded_at DESC',
    );
    return result.map(BabyGrowthRecord.fromJson).toList(growable: false);
  }

  @override
  Future<BabyGrowthRecord> updateRecord(BabyGrowthRecord record) async {
    if (record.id == null) {
      throw ArgumentError('Cannot update record without id');
    }
    final db = await _databaseHelper.database;
    final updated = record.copyWith(updatedAt: DateTime.now());
    await db.update(
      'baby_growth_records',
      updated.toJson(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    return updated;
  }
}
