enum PortionSize {
  full('전체'),
  half('반절'),
  third('1/3'),
  custom('직접');

  const PortionSize(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
