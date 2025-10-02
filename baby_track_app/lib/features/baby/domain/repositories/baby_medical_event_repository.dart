import 'package:baby_track_app/features/baby/domain/models/baby_medical_event.dart';

abstract class BabyMedicalEventRepository {
  Future<BabyMedicalEvent> createEvent(BabyMedicalEvent event);

  Future<BabyMedicalEvent> updateEvent(BabyMedicalEvent event);

  Future<void> deleteEvent(int id);

  Future<List<BabyMedicalEvent>> getEventsForBaby(int babyId);

  Future<List<BabyMedicalEvent>> getEventsForBabyOnDate(int babyId, DateTime date);

  Future<List<BabyMedicalEvent>> getUpcomingEventsForBaby(
    int babyId, {
    Duration within = const Duration(days: 7),
  });

  Future<void> markReminderSent(int eventId, {DateTime? sentAt});
}
