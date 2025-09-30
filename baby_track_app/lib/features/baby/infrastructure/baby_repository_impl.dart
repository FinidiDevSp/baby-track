import 'package:baby_track_app/features/baby/domain/models/baby.dart';
import 'package:baby_track_app/features/baby/domain/repositories/baby_repository.dart';
import 'package:baby_track_app/shared/data/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class BabyRepositoryImpl implements BabyRepository {
  final DatabaseHelper _databaseHelper;

  BabyRepositoryImpl({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  @override
  Future<List<Baby>> getAllBabies() async {
    final db = await _databaseHelper.database;
    final result = await db.query('babies', orderBy: 'created_at DESC');

    return result.map((json) => Baby.fromJson(json)).toList();
  }

  @override
  Future<Baby?> getBabyById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query('babies', where: 'id = ?', whereArgs: [id], limit: 1);

    if (result.isEmpty) {
      return null;
    }

    return Baby.fromJson(result.first);
  }

  @override
  Future<Baby> createBaby(Baby baby) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();

    final babyToInsert = baby.copyWith(createdAt: now, updatedAt: now);

    final id = await db.insert(
      'babies',
      babyToInsert.toJson()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return babyToInsert.copyWith(id: id);
  }

  @override
  Future<Baby> updateBaby(Baby baby) async {
    final db = await _databaseHelper.database;

    final babyToUpdate = baby.copyWith(updatedAt: DateTime.now());

    await db.update('babies', babyToUpdate.toJson(), where: 'id = ?', whereArgs: [baby.id]);

    return babyToUpdate;
  }

  @override
  Future<void> deleteBaby(int id) async {
    final db = await _databaseHelper.database;

    await db.delete('babies', where: 'id = ?', whereArgs: [id]);
  }
}
