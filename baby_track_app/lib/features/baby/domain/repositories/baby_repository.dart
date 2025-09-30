import 'package:baby_track_app/features/baby/domain/models/baby.dart';

abstract class BabyRepository {
  Future<List<Baby>> getAllBabies();
  Future<Baby?> getBabyById(int id);
  Future<Baby> createBaby(Baby baby);
  Future<Baby> updateBaby(Baby baby);
  Future<void> deleteBaby(int id);
}
