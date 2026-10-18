enum MealType {
  breakfast('아침'),
  lunch('점심'),
  dinner('저녁'),
  snack('간식');

  const MealType(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
