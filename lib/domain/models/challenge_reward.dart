enum ChallengeReward {
  plantExperience('식물 EXP'),
  badge('배지'),
  none('없음');

  const ChallengeReward(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
