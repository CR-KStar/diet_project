enum ActivityLevel {
  low('적음'),
  moderate('보통'),
  high('많음');

  const ActivityLevel(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
