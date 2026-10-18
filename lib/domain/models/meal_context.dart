enum MealContext {
  home('집밥'),
  lunchbox('도시락'),
  diningOut('외식'),
  delivery('배달'),
  other('기타');

  const MealContext(this.label);

  /// 화면에 보이는 이름.
  final String label;
}
