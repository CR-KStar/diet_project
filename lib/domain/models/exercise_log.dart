import 'package:diet_project/domain/models/exercise_intensity.dart';

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

  /// 사용자가 고칠 수 있는 값만 바꾼 새 기록 (날짜 · 시각 · 주인은 그대로).
  ExerciseLog copyWith({
    String? type,
    int? minutes,
    ExerciseIntensity? intensity,
    int? kcal,
  }) => ExerciseLog(
    id: id,
    userId: userId,
    type: type ?? this.type,
    minutes: minutes ?? this.minutes,
    intensity: intensity ?? this.intensity,
    kcal: kcal ?? this.kcal,
    dateKey: dateKey,
    time: time,
  );
}
