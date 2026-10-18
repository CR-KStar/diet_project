enum Gender {
  female('여성'),
  male('남성'),
  undisclosed('공개 안 함');

  const Gender(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
