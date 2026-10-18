/// UI 문구와 분리해 고정된 선택지를 안전하게 표현하는 타입입니다.
enum DietGoal {
  loseWeight('체중 감량'),
  maintainWeight('체중 유지'),
  gainMuscle('근육 증가');

  const DietGoal(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
