/// AI가 조건에 맞춰 추천해 준 메뉴 하나.
class AiMealSuggestion {
  const AiMealSuggestion({
    required this.name,
    required this.emoji,
    required this.kcal,
    required this.meta,
    required this.covers,
    required this.prefs,
    required this.meals,
    required this.tag,
    required this.why,
    required this.score,
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
  final int score;
}
