/// 식단 추천 화면에 노출되는 추천 메뉴 모델.
class MealSuggestion {
  const MealSuggestion({
    required this.name,
    required this.emoji,
    required this.kcal,
    required this.meta,
    required this.covers,
    required this.prefs,
    required this.meals,
    required this.tag,
    required this.why,
  });

  final String name;
  final String emoji;
  final int kcal;
  final String meta;
  final List<String> covers;
  final List<String> prefs;
  final List<String> meals;
  final String tag;
  final String why;
}
