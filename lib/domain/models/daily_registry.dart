import 'package:diet_project/domain/models/exercise_log.dart';
import 'package:diet_project/domain/models/meal_log.dart';
import 'package:diet_project/domain/models/water_entry.dart';
import 'package:diet_project/domain/models/weight_entry.dart';

/// 하루 요약 장부 — 저장되는 데이터가 아니라, 한 사용자의 하루치 기록을 묶어 합계를 계산합니다.
class DailyRegistry {
  DailyRegistry({
    required this.userId,
    required this.dateKey,
    required this.meals,
    required this.waterEntries,
    required this.exerciseLogs,
    required this.weightEntry,
  });

  final String userId;
  final String dateKey;
  final List<MealLog> meals;
  final List<WaterEntry> waterEntries;
  final List<ExerciseLog> exerciseLogs;
  final WeightEntry? weightEntry;

  int get totalIntakeKcal => meals.fold(0, (sum, m) => sum + m.kcal);
  int get totalWaterMl => waterEntries.fold(0, (sum, w) => sum + w.ml);
  int get totalBurnedKcal => exerciseLogs.fold(0, (sum, e) => sum + e.kcal);
  int get totalExerciseMinutes =>
      exerciseLogs.fold(0, (sum, e) => sum + e.minutes);
}
