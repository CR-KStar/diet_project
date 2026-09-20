import 'enums.dart';

/// 식단 기록
class MealLog {
  const MealLog({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.name,
    required this.meta,
    required this.kcal,
    required this.dateKey,
    this.bowlId,
    this.needsReview = false,
  });

  final String id;
  final String userId;

  /// 끼니 종류는 enum으로 보관하고, 화면은 기존처럼 `type` 문구를 읽습니다.
  final MealType mealType;
  String get type => mealType.label;
  final String name;
  final String meta;
  final int kcal;
  final String dateKey;
  final String? bowlId;
  final bool needsReview;
}

/// 물 섭취 기록
class WaterEntry {
  WaterEntry({
    required this.id,
    required this.userId,
    required this.ml,
    required this.time,
  });

  final String id;
  final String userId;
  int ml;
  final String time;
}

/// 체중 기록
class WeightEntry {
  WeightEntry({
    required this.id,
    required this.userId,
    required this.kg,
    required this.dateKey,
    required this.time,
  });

  final String id;
  final String userId;
  final double kg;
  final String dateKey;
  final String time;
}

/// 운동 기록
class ExerciseLog {
  ExerciseLog({
    required this.id,
    required this.userId,
    required this.type,
    required this.minutes,
    required this.intensity,
    required this.kcal,
    required this.dateKey,
    required this.time,
  });

  final String id;
  final String userId;
  final String type;
  final int minutes;
  final ExerciseIntensity intensity;
  final int kcal;
  final String dateKey;
  final String time;
}

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
  int get totalExerciseMinutes => exerciseLogs.fold(0, (sum, e) => sum + e.minutes);
}

/// 기록용 템플릿: 그릇
class Bowl {
  Bowl({
    required this.id,
    required this.userId,
    required this.name,
    required this.capacityMl,
    required this.portion,
    required this.material,
    required this.shape,
    this.memo = '',
    this.isDefault = false,
    this.icon = '🥣',
  });

  final String id;
  final String userId;
  String name;
  int capacityMl;
  String portion;
  String material;
  String shape;
  String memo;
  bool isDefault;
  String icon;

  double get capacityFactor => capacityMl >= 800 ? 1.2 : (capacityMl >= 450 ? 1.0 : 0.6);
  String get meta => '$capacityMl ml · $portion · $material';
}

/// 기록용 템플릿: 운동 루틴
class Routine {
  Routine({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.minutes,
    required this.intensity,
    this.icon = '💪',
    this.used = 0,
    this.weeklyUsed = 0,
  });

  final String id;
  final String userId;
  String name;
  String type;
  int minutes;
  ExerciseIntensity intensity;
  String icon;
  int used;
  int weeklyUsed;

  String get meta => '$type · $minutes분 · ${intensity.label}';
}
