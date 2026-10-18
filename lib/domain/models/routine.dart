import 'package:diet_project/domain/models/exercise_intensity.dart';

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
