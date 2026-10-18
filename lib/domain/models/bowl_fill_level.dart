enum BowlFillLevel {
  full('가득'),
  half('반'),
  third('1/3');

  const BowlFillLevel(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
