enum ShareScope {
  private('비공개'),
  friends('친구만');

  const ShareScope(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
