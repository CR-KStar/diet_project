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
}
