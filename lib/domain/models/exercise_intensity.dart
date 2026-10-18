enum ExerciseIntensity {
  low('낮음'),
  moderate('보통'),
  high('높음');

  const ExerciseIntensity(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
