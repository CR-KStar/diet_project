import 'package:diet_project/domain/models/exercise_intensity.dart';

/// 운동을 저장하기 전 입력하는 값입니다.
class ExerciseDraft {
  ExerciseDraft({
    this.type = '달리기',
    this.minutes = 30,
    this.intensity = ExerciseIntensity.moderate,
  });

  String type;
  int minutes;
  ExerciseIntensity intensity;
}
