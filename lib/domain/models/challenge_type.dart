enum ChallengeType {
  water('물 마시기'),
  exercise('운동 시간'),
  mealRecord('식단 기록'),
  protein('단백질');

  const ChallengeType(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
